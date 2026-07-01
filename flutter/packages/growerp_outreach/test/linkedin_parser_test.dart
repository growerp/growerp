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

  test('parseLinkedInConnectionsCsv keeps non-Latin profile urls valid ascii',
      () {
    const csv =
        'First Name,Last Name,URL,Email Address,Company,Position,Connected On\n'
        'Nok,Thai,https://www.linkedin.com/in/%E0%B8%95%E0%B9%89%E0%B8%99,'
        'a@b.com,Acme,CEO,01 Jan 2024\n';
    final leads = parseLinkedInConnectionsCsv(csv);
    expect(leads.length, 1);
    final url = leads.first.url!;
    // non-Latin vanity names stay percent-encoded so the backend WebAddress
    // URL validation accepts them, and the url fits the 255-char column.
    expect(url, matches(RegExp(r'^[\x00-\x7F]+$')));
    expect(url, startsWith('https://www.linkedin.com/in/'));
    expect(url.length, lessThan(255));
  });

  test('parseLinkedInConnectionsCsv encodes raw unicode profile urls', () {
    const csv =
        'First Name,Last Name,URL,Email Address,Company,Position,Connected On\n'
        'Hieu,Nguyen,https://www.linkedin.com/in/hiếu-nguyễn-563693227,'
        'a@b.com,Acme,CEO,01 Jan 2024\n';
    final leads = parseLinkedInConnectionsCsv(csv);
    final url = leads.first.url!;
    expect(url, matches(RegExp(r'^[\x00-\x7F]+$')));
    expect(url, contains('%'));
  });

  test('parseLinkedInConnectionsCsv rejects a non-LinkedIn file', () {
    expect(
      () => parseLinkedInConnectionsCsv('a,b,c\n1,2,3\n'),
      throwsA(isA<String>()),
    );
  });
}
