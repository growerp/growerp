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

import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import '../../../l10n/generated/support_localizations.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../website_conversion.dart';

/// Website generator: convert an existing company website into a new owner.
/// Each row is one conversion; the ones still running refresh themselves.
class WebsiteConversionList extends StatefulWidget {
  const WebsiteConversionList({super.key});

  @override
  WebsiteConversionListState createState() => WebsiteConversionListState();
}

class WebsiteConversionListState extends State<WebsiteConversionList> {
  final _scrollController = ScrollController();
  late WebsiteConversionBloc _bloc;
  List<WebsiteConversion> _conversions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<WebsiteConversionBloc>()
      ..add(const WebsiteConversionFetch(refresh: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Write the rebuilt owner-import XML where the user picks, so it can be moved
  /// to another installation or committed next to the other example files.
  Future<void> _saveExport(WebsiteExport export) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(export.xmlText));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save the website export',
        fileName: export.fileName.isEmpty
            ? 'WebsiteOwnerImportData.xml'
            : export.fileName,
        type: FileType.custom,
        allowedExtensions: ['xml'],
        bytes: bytes, // web and mobile need the content up front
      );
      if (!mounted) return;
      if (path == null) return; // cancelled
      if (!foundation.kIsWeb) {
        // on desktop saveFile only returns the chosen path, it writes nothing
        await File(path).writeAsBytes(bytes);
      }
      if (!mounted) return;
      HelperFunctions.showMessage(context, 'Saved as $path', Colors.green);
    } catch (e) {
      if (!mounted) return;
      HelperFunctions.showMessage(context, 'Could not save: $e', Colors.red);
    }
  }

  /// Install an owner-import XML: one exported here, or one /convert-website made.
  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['xml'],
      type: FileType.custom,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    String content;
    if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      return;
    }
    if (!mounted) return;
    _bloc.add(WebsiteConversionImportFile(content, file.name));
  }

  void _openDialog(WebsiteConversion? conversion) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider.value(
        value: _bloc,
        child: WebsiteConversionDialog(conversion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebsiteConversionBloc, WebsiteConversionState>(
      listener: (context, state) {
        if (state.status == WebsiteConversionStatus.exportReady &&
            state.export != null) {
          _saveExport(state.export!);
          return;
        }
        if (state.status == WebsiteConversionStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        } else if (state.message != null && state.message!.isNotEmpty) {
          // covers both "started in the background" and the poll noticing that a
          // conversion finished; a poll without news carries no message
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        _isLoading = state.status == WebsiteConversionStatus.loading;
        if (state.status == WebsiteConversionStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        _conversions = state.conversions;
        return Scaffold(
          // the route is the form key the route walking tests look for
          key: const Key('/websiteGenerator'),
          floatingActionButton: FloatingActionButton(
            key: const Key('addNewWebsiteConversion'),
            onPressed: () => _openDialog(null),
            tooltip: 'Convert a website',
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              ListFilterBar(
                key: const Key('websiteConversionSearch'),
                searchHint: SupportLocalizations.of(
                  context,
                )!.searchHintWebsiteConversion,
                searchValue: state.searchString,
                onSearchChanged: (value) => _bloc.add(
                  WebsiteConversionFetch(searchString: value, refresh: true),
                ),
                actions: [
                  IconButton(
                    key: const Key('importWebsiteFile'),
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Install a website from an export file',
                    onPressed: _pickAndImport,
                  ),
                ],
              ),
              Expanded(
                child: _conversions.isEmpty && !_isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            SupportLocalizations.of(
                              context,
                            )!.noWebsitesConverted,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : StyledDataTable(
                        columns: getWebsiteConversionListColumns(context),
                        rows: _conversions
                            .map(
                              (conversion) => getWebsiteConversionListRow(
                                context: context,
                                conversion: conversion,
                                index: _conversions.indexOf(conversion),
                                onExport: (c) =>
                                    _bloc.add(WebsiteConversionExport(c)),
                              ),
                            )
                            .toList(),
                        isLoading: _isLoading && _conversions.isEmpty,
                        scrollController: _scrollController,
                        rowHeight: isAPhone(context) ? 72 : 56,
                        onRowTap: (index) => _openDialog(_conversions[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
