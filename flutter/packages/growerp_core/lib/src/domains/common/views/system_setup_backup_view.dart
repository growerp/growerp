/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:growerp_core/growerp_core.dart';

/// Backup of the company data: download all data as one zip (standard Moqui
/// data files), as a backup or to move the company to another system. System
/// support can also upload such a zip as a new company.
///
/// Files of any size: both run in the background on the backend (this view
/// polls the progress), the download is a link the browser saves, the upload
/// goes in chunks.
///
/// Used as the Backup tab of System Setup, inside [SystemSetupDialog], and by
/// system support for any owner from the owners list.
class SystemSetupBackupView extends StatefulWidget {
  /// The owner to download, system support only; null: the user's own.
  final String? ownerPartyId;

  /// Show the download part.
  final bool download;

  /// Show the upload part; null: when the user is system support.
  final bool? upload;

  /// False when embedded next to another section, which then draws the outer
  /// scroll view and padding.
  final bool standalone;

  const SystemSetupBackupView({
    super.key,
    this.ownerPartyId,
    this.download = true,
    this.upload,
    this.standalone = true,
  });

  @override
  State<SystemSetupBackupView> createState() => _SystemSetupBackupViewState();
}

class _SystemSetupBackupViewState extends State<SystemSetupBackupView> {
  /// Below the request size limit of the proxies (20 MB).
  static const int chunkSize = 8 * 1024 * 1024;

  RestClient? _restClient;
  OwnerDataTransfer? _download;
  OwnerDataTransfer? _upload;
  Timer? _timer;
  bool _isLoading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restClient = context.read<RestClient>();
      _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _showUpload =>
      widget.upload ??
      context.read<AuthBloc>().state.authenticate?.user?.userGroup ==
          UserGroup.system;

  Future<void> _load() async {
    try {
      final download = widget.download
          ? await _restClient!.getOwnerDataTransfer(
              direction: 'EXPORT',
              ownerPartyId: widget.ownerPartyId,
            )
          : null;
      final upload = _showUpload
          ? await _restClient!.getOwnerDataTransfer(direction: 'IMPORT')
          : null;
      if (!mounted) return;
      setState(() {
        _download = download?.status == null ? null : download;
        _upload = upload?.status == null ? null : upload;
      });
      _pollWhileRunning();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pollWhileRunning() {
    _timer?.cancel();
    final downloadRunning = _download?.isRunning ?? false;
    final uploadRunning = !_sending && (_upload?.isRunning ?? false);
    if (!downloadRunning && !uploadRunning) return;
    _timer = Timer(const Duration(seconds: 2), () async {
      try {
        if (downloadRunning) {
          final job = await _restClient!.getOwnerDataTransfer(
            ownerDataTransferId: _download!.ownerDataTransferId,
            ownerPartyId: widget.ownerPartyId,
          );
          if (!mounted) return;
          setState(() => _download = job);
          if (job.downloadPath != null) await _save(job);
        }
        if (uploadRunning) {
          final job = await _restClient!.getOwnerDataTransfer(
            ownerDataTransferId: _upload!.ownerDataTransferId,
          );
          if (!mounted) return;
          setState(() => _upload = job);
        }
        _pollWhileRunning();
      } catch (e) {
        _error(e);
      }
    });
  }

  Future<void> _startDownload() async {
    try {
      final job = await _restClient!.createOwnerDataExport(
        ownerPartyId: widget.ownerPartyId,
      );
      if (!mounted) return;
      setState(() => _download = job);
      _pollWhileRunning();
    } catch (e) {
      _error(e);
    }
  }

  /// The browser saves the file: streamed, any size, on every platform.
  Future<void> _save(OwnerDataTransfer job) async {
    try {
      final dio = await buildDioClient();
      final base = dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
      await launchUrl(
        Uri.parse('$base${job.downloadPath}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _error(e);
    }
  }

  /// Sent in chunks while reading the file, never the whole file in memory.
  Future<void> _startUpload() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      String? id;
      int offset = 0;
      final buffer = BytesBuilder(copy: false);
      Future<void> send(bool last) async {
        final bytes = buffer.takeBytes();
        final job = await _restClient!.uploadOwnerDataChunk(
          ownerDataTransferId: id,
          fileName: picked.name,
          offset: '$offset',
          last: '$last',
          file: MultipartFile.fromBytes(bytes, filename: picked.name),
        );
        id = job.ownerDataTransferId;
        offset += bytes.length;
        if (mounted) setState(() => _upload = job);
      }

      await for (final data in picked.readAsByteStream()) {
        buffer.add(data);
        while (buffer.length >= chunkSize) {
          final all = buffer.takeBytes();
          buffer.add(Uint8List.sublistView(all, 0, chunkSize));
          await send(false);
          buffer.add(Uint8List.sublistView(all, chunkSize));
        }
      }
      await send(true);
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _sending = false);
      _pollWhileRunning();
    }
  }

  Future<void> _error(Object e) async {
    final message = await getDioError(e);
    if (!mounted) return;
    HelperFunctions.showMessage(
      context,
      message.isNotEmpty ? message : '$e',
      Theme.of(context).colorScheme.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final localizations = CoreLocalizations.of(context)!;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.download)
          GroupingDecorator(
            decoratorKey: const Key('ownerDataDownloadSection'),
            labelText: localizations.ownerDataDownload,
            icon: Icons.download_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.ownerDataDownloadInfo),
                const SizedBox(height: 8),
                Text(
                  localizations.ownerDataSensitive,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                _status(_download, const Key('ownerDataDownloadStatus')),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('ownerDataDownload'),
                        icon: const Icon(Icons.download),
                        label: Text(localizations.ownerDataDownload),
                        onPressed: (_download?.isRunning ?? false)
                            ? null
                            : _startDownload,
                      ),
                      // a finished download can be saved again for 24 hours
                      if (_download?.downloadPath != null)
                        TextButton.icon(
                          key: const Key('ownerDataSave'),
                          icon: const Icon(Icons.save_alt),
                          label: Text(localizations.ownerDataSave),
                          onPressed: () => _save(_download!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (widget.download && _showUpload) const SizedBox(height: 24),
        if (_showUpload)
          GroupingDecorator(
            decoratorKey: const Key('ownerDataUploadSection'),
            labelText: localizations.ownerDataUpload,
            icon: Icons.upload_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.ownerDataUploadInfo),
                const SizedBox(height: 16),
                _status(_upload, const Key('ownerDataUploadStatus')),
                if (_upload?.status == 'DONE' &&
                    _upload?.newOwnerPartyId != null)
                  Text(
                    localizations.ownerDataUploaded(_upload!.newOwnerPartyId!),
                    key: const Key('ownerDataUploaded'),
                  ),
                const SizedBox(height: 8),
                Center(
                  child: OutlinedButton.icon(
                    key: const Key('ownerDataUpload'),
                    icon: const Icon(Icons.upload),
                    label: Text(localizations.ownerDataUpload),
                    onPressed: _sending || (_upload?.isRunning ?? false)
                        ? null
                        : _startUpload,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (!widget.standalone) return content;

    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return SingleChildScrollView(
      key: const Key('SystemSetupBackupView'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isPhone ? 600 : 1000),
          child: content,
        ),
      ),
    );
  }

  /// The latest job: running with its progress, done, or failed with why.
  Widget _status(OwnerDataTransfer? job, Key key) {
    if (job == null) return const SizedBox.shrink();
    final localizations = CoreLocalizations.of(context)!;
    final when = job.completedDate ?? job.createdDate;
    final bytes = job.fileSize ?? 0;
    final size = bytes == 0
        ? ''
        : bytes < 1024 * 1024
        ? ' (${(bytes / 1024).ceil()} KB)'
        : ' (${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB)';
    final text = switch (job.status) {
      'DONE' => '${localizations.ownerDataDone}: ${job.progress ?? ''}$size',
      'FAILED' => '${localizations.ownerDataFailed}: ${job.errorMessage ?? ''}',
      _ => '${job.progress ?? job.status ?? ''}$size',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (job.isRunning || (_sending && job == _upload))
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Expanded(
            child: Text(
              when == null ? text : '${when.toLocal().dateOnly()} $text',
              key: key,
            ),
          ),
        ],
      ),
    );
  }
}
