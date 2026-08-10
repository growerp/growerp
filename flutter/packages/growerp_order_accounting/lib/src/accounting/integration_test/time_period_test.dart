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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';

class TimePeriodTest {
  static AuthBloc _authBloc(WidgetTester tester) => BlocProvider.of<AuthBloc>(
    tester.element(find.byType(MaterialApp).first),
  );

  /// Change the month the accounting year starts, which recreates all periods.
  static Future<void> setFiscalYearStart(
    WidgetTester tester,
    int startMonth,
  ) async {
    final authBloc = _authBloc(tester);
    final company = authBloc.state.authenticate!.company!;
    await authBloc.restClient.updateCompany(
      company: company.copyWith(fiscalYearStartMonth: startMonth),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  /// The fiscal year, its four quarters and its twelve months all start at
  /// [startMonth] and are named after the year the fiscal year started in.
  static Future<void> checkFiscalPeriods(
    WidgetTester tester,
    int startMonth,
  ) async {
    final restClient = _authBloc(tester).restClient;

    final years = (await restClient.getTimePeriod(periodType: 'Y')).timePeriods;
    expect(years, isNotEmpty, reason: 'no fiscal years created');
    final currentYear = years.firstWhere(
      (period) => period.fromDate!.month == startMonth,
      orElse: () => throw TestFailure(
        'no fiscal year starting in month $startMonth: '
        '${years.map((p) => '${p.periodName}:${p.fromDate}').toList()}',
      ),
    );
    expect(currentYear.fromDate!.day, equals(1));
    expect(
      currentYear.thruDate,
      equals(
        DateTime(
          currentYear.fromDate!.year + 1,
          startMonth,
          1,
        ).subtract(const Duration(days: 1)),
      ),
    );
    expect(currentYear.periodName, equals('Y${currentYear.fromDate!.year}'));

    // quarters of that fiscal year: q01..q04 three months apart
    final quarters = List.of(
      (await restClient.getTimePeriod(
        periodType: 'Q',
        year: '${currentYear.fromDate!.year}',
      )).timePeriods,
    )..sort((a, b) => a.periodName.compareTo(b.periodName));
    expect(quarters.length, equals(4), reason: 'expected 4 quarters');
    for (int quarter = 0; quarter < 4; quarter++) {
      expect(
        quarters[quarter].periodName,
        equals('Y${currentYear.fromDate!.year}q0${quarter + 1}'),
      );
      expect(
        quarters[quarter].fromDate!.month,
        equals((startMonth - 1 + quarter * 3) % 12 + 1),
      );
      expect(quarters[quarter].fromDate!.day, equals(1));
    }

    // months of that fiscal year: m01..m12 one month apart
    final months = List.of(
      (await restClient.getTimePeriod(
        periodType: 'M',
        year: '${currentYear.fromDate!.year}',
      )).timePeriods,
    )..sort((a, b) => a.periodName.compareTo(b.periodName));
    expect(months.length, equals(12), reason: 'expected 12 months');
    for (int month = 0; month < 12; month++) {
      expect(
        months[month].fromDate!.month,
        equals((startMonth - 1 + month) % 12 + 1),
      );
      expect(months[month].fromDate!.day, equals(1));
    }
  }

  /// Close the first, already ended, month of the oldest fiscal year.
  static Future<void> closeFirstMonth(WidgetTester tester) async {
    final restClient = _authBloc(tester).restClient;
    final months = List.of(
      (await restClient.getTimePeriod(periodType: 'M')).timePeriods,
    )..sort((a, b) => a.fromDate!.compareTo(b.fromDate!));
    await restClient.closeTimePeriod(timePeriodId: months.first.periodId);
    await tester.pump(const Duration(seconds: 2));
  }

  /// Once something is posted or closed the accounting year and the currency
  /// are fixed: the company reports it and the backend refuses the change.
  static Future<void> checkAcctgChangeLocked(
    WidgetTester tester,
    int otherStartMonth,
  ) async {
    final authBloc = _authBloc(tester);
    final company = authBloc.state.authenticate!.company!;
    final companies = await authBloc.restClient.getCompany(
      companyPartyId: company.partyId,
    );
    expect(companies.companies.first.acctPeriodChangeAllowed, isFalse);

    await expectLater(
      authBloc.restClient.updateCompany(
        company: companies.companies.first.copyWith(
          fiscalYearStartMonth: otherStartMonth,
        ),
      ),
      throwsA(isA<DioException>()),
    );
  }
}
