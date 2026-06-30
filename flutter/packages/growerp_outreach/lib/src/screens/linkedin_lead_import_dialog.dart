/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:math';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Import a LinkedIn "Connections" export (CSV) as GrowERP leads.
///
/// Each row becomes a lead User (role: Lead -> CUSTOMER_ASSIGNED / unqualified).
/// When the row has a Company, the backend import#CompanyUsers creates that
/// company if it does not yet exist (matched by name) and links the person to it.
class LinkedInLeadImportDialog extends StatefulWidget {
  const LinkedInLeadImportDialog({super.key, required this.restClient});

  final RestClient restClient;

  @override
  State<LinkedInLeadImportDialog> createState() =>
      _LinkedInLeadImportDialogState();
}

class _LinkedInLeadImportDialogState extends State<LinkedInLeadImportDialog> {
  bool _busy = false;
  String? _status;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['csv'],
      type: FileType.custom,
      withData: foundation.kIsWeb,
    );
    if (result == null) return;

    String fileString;
    if (foundation.kIsWeb) {
      fileString = String.fromCharCodes(result.files.first.bytes!);
    } else {
      fileString = await File(result.files.single.path!).readAsString();
    }

    try {
      final leads = _parseLinkedInCsv(fileString);
      if (leads.isEmpty) {
        setState(() => _status = 'No leads found in the file.');
        return;
      }
      setState(() {
        _busy = true;
        _status = 'Importing ${leads.length} leads…';
      });

      const batch = 500;
      int done = 0;
      for (var i = 0; i < leads.length; i += batch) {
        final chunk = leads.sublist(i, min(i + batch, leads.length));
        await widget.restClient.importCompanyUsers(chunk);
        done += chunk.length;
        if (mounted) setState(() => _status = 'Imported $done / ${leads.length}…');
      }

      if (!mounted) return;
      HelperFunctions.showMessage(
          context, 'Imported $done leads', Colors.green);
      Navigator.of(context).pop(done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Import failed: $e';
      });
      HelperFunctions.showMessage(context, 'Import failed: $e', Colors.red);
    }
  }

  /// Parse a LinkedIn Connections CSV (skips the notes preamble, maps columns by
  /// header name so column order does not matter).
  List<CompanyUser> _parseLinkedInCsv(String fileString) {
    final rows = fast_csv.parse(fileString);
    final headerIdx = rows.indexWhere(
        (r) => r.any((c) => c.trim().toLowerCase() == 'first name'));
    if (headerIdx == -1) {
      throw 'No "First Name" header row found — is this a LinkedIn connections export?';
    }
    final header = rows[headerIdx].map((c) => c.trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name);
    final iFirst = col('first name'),
        iLast = col('last name'),
        iUrl = col('url'),
        iEmail = col('email address'),
        iCompany = col('company');

    final leads = <CompanyUser>[];
    for (var i = headerIdx + 1; i < rows.length; i++) {
      final r = rows[i];
      String cell(int idx) => (idx >= 0 && idx < r.length) ? r[idx].trim() : '';
      final first = cell(iFirst), last = cell(iLast);
      if (first.isEmpty && last.isEmpty) continue;
      final company = cell(iCompany);
      leads.add(CompanyUser(
        type: PartyType.user,
        role: Role.lead,
        name: '$first $last'.trim(),
        email: cell(iEmail),
        url: cell(iUrl),
        company:
            company.isNotEmpty ? Company(name: company, role: Role.lead) : null,
      ));
    }
    return leads;
  }

  @override
  Widget build(BuildContext context) {
    return popUpDialog(
      context: context,
      title: 'Import LinkedIn leads',
      children: [
        const SizedBox(height: 20),
        const Text(
          'Upload a LinkedIn "Connections" CSV export. Each contact becomes a '
          'lead; its company is created if new and linked to the person.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('uploadLinkedIn'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Choose CSV file'),
          onPressed: _busy ? null : _pickAndImport,
        ),
        const SizedBox(height: 16),
        if (_status != null) Text(_status!, textAlign: TextAlign.center),
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
