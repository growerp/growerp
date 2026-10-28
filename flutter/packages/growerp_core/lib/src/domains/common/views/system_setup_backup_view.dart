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
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:growerp_core/growerp_core.dart';

/// Backup tab of System Setup: download all data of the company as one zip
/// (standard Moqui data files), as a backup or to move it to another system.
/// System support can also upload such a zip as a new company.
///
/// Both run in the background on the backend, this view polls the progress.
class SystemSetupBackupView extends StatefulWidget {
  const SystemSetupBackupView({super.key});

  @override
  State<SystemSetupBackupView> createState() => _SystemSetupBackupViewState();
}

class _SystemSetupBackupViewState extends State<SystemSetupBackupView> {
  RestClient? _restClient;
  OwnerDataTransfer? _download;
  OwnerDataTransfer? _upload;
  Timer? _timer;
  bool _isLoading = true;

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

  bool get _isSupport =>
      context.read<AuthBloc>().state.authenticate?.user?.userGroup ==
      UserGroup.system;

  Future<void> _load() async {
    try {
      final download = await _restClient!.getOwnerDataTransfer(
        direction: 'EXPORT',
      );
      final upload = _isSupport
          ? await _restClient!.getOwnerDataTransfer(direction: 'IMPORT')
          : null;
      if (!mounted) return;
      setState(() {
        _download = download.status == null ? null : download;
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
    if (!(_download?.isRunning ?? false) && !(_upload?.isRunning ?? false)) {
      return;
    }
    _timer = Timer(const Duration(seconds: 2), () async {
      try {
        if (_download?.isRunning ?? false) {
          final job = await _restClient!.getOwnerDataTransfer(
            ownerDataTransferId: _download!.ownerDataTransferId,
          );
          if (!mounted) return;
          setState(() => _download = job);
          if (job.status == 'DONE') await _save(job);
        }
        if (_upload?.isRunning ?? false) {
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
      final job = await _restClient!.createOwnerDataExport();
      if (!mounted) return;
      setState(() => _download = job);
      _pollWhileRunning();
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _save(OwnerDataTransfer job) async {
    try {
      final result = await _restClient!.getOwnerDataExportFile(
        ownerDataTransferId: job.ownerDataTransferId!,
      );
      final file = result is String ? jsonDecode(result) : result;
      if (!mounted) return;
      await FilePicker.saveFile(
        dialogTitle: CoreLocalizations.of(context)!.ownerDataDownload,
        fileName: file['fileName'] as String,
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: base64Decode(file['zip'] as String),
      );
    } catch (e) {
      _error(e);
    }
  }

  Future<void> _startUpload() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (picked == null) return;
    try {
      final job = await _restClient!.createOwnerDataImport(
        data: {
          'fileName': picked.name,
          'zip': base64Encode(await picked.readAsBytes()),
        },
      );
      if (!mounted) return;
      setState(() => _upload = job);
      _pollWhileRunning();
    } catch (e) {
      _error(e);
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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return SingleChildScrollView(
      key: const Key('SystemSetupBackupView'),
      padding: EdgeInsets.all(isPhone ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isPhone ? 600 : 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _status(_download, const Key('ownerDataDownloadStatus')),
                    Center(
                      child: OutlinedButton.icon(
                        key: const Key('ownerDataDownload'),
                        icon: const Icon(Icons.download),
                        label: Text(localizations.ownerDataDownload),
                        onPressed: (_download?.isRunning ?? false)
                            ? null
                            : _startDownload,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSupport) ...[
                const SizedBox(height: 24),
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
                          localizations.ownerDataUploaded(
                            _upload!.newOwnerPartyId!,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          key: const Key('ownerDataUpload'),
                          icon: const Icon(Icons.upload),
                          label: Text(localizations.ownerDataUpload),
                          onPressed: (_upload?.isRunning ?? false)
                              ? null
                              : _startUpload,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The latest job: running with its progress, done, or failed with why.
  Widget _status(OwnerDataTransfer? job, Key key) {
    if (job == null) return const SizedBox.shrink();
    final localizations = CoreLocalizations.of(context)!;
    final when = job.completedDate ?? job.createdDate;
    final text = switch (job.status) {
      'DONE' => '${localizations.ownerDataDone}: ${job.progress ?? ''}',
      'FAILED' => '${localizations.ownerDataFailed}: ${job.errorMessage ?? ''}',
      _ => job.progress ?? job.status ?? '',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (job.isRunning)
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
