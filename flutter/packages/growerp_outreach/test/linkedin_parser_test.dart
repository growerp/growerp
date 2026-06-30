/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License. See the LICENSE.md file.
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_outreach/growerp_outreach.dart';

/// Pure-Dart test of the LinkedIn connections CSV parser (no backend).
void main() {
  test('parseLinkedInConnectionsCsv maps the sample export', () {
    final csv = File(
      'example/integration_test/data/linkedin_connections_sample.csv',
    ).readAsStringSync();
    final leads = parseLinkedInConnectionsCsv(csv);

    // 5 data rows past the notes preamble + header.
    expect(leads.length, 5);

    final alice = leads.firstWhere((l) => l.name == 'Alice Anderson');
    expect(alice.type, PartyType.user);
    expect(alice.role, Role.lead);
    expect(alice.personalTitle, 'CEO'); // Position -> personalTitle
    expect(alice.email, 'alice@acme.com');
    expect(alice.company?.name, 'Acme Corp');
    expect(alice.company?.role, Role.lead);

    // Carol: no email but a company.
    final carol = leads.firstWhere((l) => l.name == 'Carol Clark');
    expect(carol.email, '');
    expect(carol.company?.name, 'Globex');

    // Eve: no company column -> no related company.
    expect(leads.firstWhere((l) => l.name == 'Eve Evans').company, isNull);

    // Two contacts share "Acme Corp" (de-dup happens server-side on import).
    expect(leads.where((l) => l.company?.name == 'Acme Corp').length, 2);
  });

  test('parseLinkedInConnectionsCsv rejects a non-LinkedIn file', () {
    expect(
      () => parseLinkedInConnectionsCsv('a,b,c\n1,2,3\n'),
      throwsA(isA<String>()),
    );
  });
}
