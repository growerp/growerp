import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';
import 'package:growerp_adk/src/adk_schedule.dart';

/// delta = serverUtcOffset - localUtcOffset (minutes): server time = local + delta
const bangkokOnUtc = -420; // user UTC+7, server UTC
const utcOnBangkok = 420;
const indiaOnUtc = -330; // user UTC+5:30, server UTC

void main() {
  final l = lookupAdkLocalizations(const Locale('en'));
  String toServer(AgentSchedule s, int delta) => s.toServerCron(delta).$1!;

  group('local to server cron', () {
    test('same time zone', () {
      expect(toServer(AgentSchedule.dailyAtNine, 0), '0 0 9 * * ?');
    });

    test('daily shifts the hour', () {
      expect(toServer(AgentSchedule.dailyAtNine, bangkokOnUtc), '0 0 2 * * ?');
    });

    test('weekdays move to the previous day across midnight', () {
      const s = AgentSchedule(
          kind: ScheduleKind.daily, hour: 6, days: AgentSchedule.weekdays);
      // 06:00 Bangkok = 23:00 UTC the day before
      expect(toServer(s, bangkokOnUtc), '0 0 23 ? * MON-THU,SUN');
    });

    test('half-hour time zone shifts the minute', () {
      expect(toServer(AgentSchedule.dailyAtNine, indiaOnUtc), '0 30 3 * * ?');
    });

    test('every 30 minutes in an hour window', () {
      const s = AgentSchedule(
          kind: ScheduleKind.minutes, everyMinutes: 30, hours: {9, 10, 11, 12, 13, 14, 15, 16, 17});
      expect(toServer(s, bangkokOnUtc), '0 */30 2-10 * * ?');
    });

    test('window crossing server midnight becomes two ranges', () {
      const s = AgentSchedule(kind: ScheduleKind.hourly, hours: {5, 6, 7, 8, 9});
      expect(toServer(s, bangkokOnUtc), '0 0 0-2,22-23 * * ?');
    });

    test('window crossing server midnight with some days is an error', () {
      const s = AgentSchedule(
          kind: ScheduleKind.hourly, hours: {5, 6, 7, 8, 9}, days: AgentSchedule.weekdays);
      expect(s.toServerCron(bangkokOnUtc).$2, ScheduleError.crossesMidnight);
    });

    test('window with some days that stays on one server day', () {
      const s = AgentSchedule(
          kind: ScheduleKind.hourly, minute: 15, hours: {9, 10, 11}, days: AgentSchedule.weekdays);
      expect(toServer(s, bangkokOnUtc), '0 15 2-4 ? * MON-FRI');
    });

    test('hour window with a half-hour zone is an error for every few minutes', () {
      const s = AgentSchedule(kind: ScheduleKind.minutes, everyMinutes: 15, hours: {9, 10});
      expect(s.toServerCron(indiaOnUtc).$2, ScheduleError.partialHourWindow);
    });

    test('every 15 minutes all day with a half-hour zone moves the start minute', () {
      const s = AgentSchedule(kind: ScheduleKind.minutes, everyMinutes: 20);
      expect(toServer(s, indiaOnUtc), '0 10/20 * * * ?');
    });

    test('monthly on day 1 early morning becomes the last day of the month', () {
      const s = AgentSchedule(kind: ScheduleKind.monthly, hour: 3, dayOfMonth: 1);
      expect(toServer(s, bangkokOnUtc), '0 0 20 L * ?');
    });

    test('monthly day 28 late evening on an eastern server is an error', () {
      const s = AgentSchedule(kind: ScheduleKind.monthly, hour: 22, dayOfMonth: 28);
      expect(s.toServerCron(utcOnBangkok).$2, ScheduleError.monthEnd);
    });

    test('custom passes through', () {
      const s = AgentSchedule(kind: ScheduleKind.custom, cron: '0 0 12 1/2 * ?');
      expect(toServer(s, bangkokOnUtc), '0 0 12 1/2 * ?');
    });
  });

  group('server cron to local', () {
    for (final delta in [0, bangkokOnUtc, utcOnBangkok, indiaOnUtc]) {
      test('round trips at delta $delta', () {
        final schedules = [
          AgentSchedule.dailyAtNine,
          const AgentSchedule(kind: ScheduleKind.daily, hour: 6, minute: 30, days: AgentSchedule.weekdays),
          const AgentSchedule(kind: ScheduleKind.hourly, minute: 45),
          const AgentSchedule(kind: ScheduleKind.minutes, everyMinutes: 10),
          const AgentSchedule(kind: ScheduleKind.monthly, hour: 12, dayOfMonth: 15),
        ];
        for (final s in schedules) {
          final cron = toServer(s, delta);
          final back = AgentSchedule.fromServerCron(cron, delta);
          expect(back.toCron(), s.toCron(), reason: 'via $cron');
        }
      });
    }

    test('seed crons read as plain schedules', () {
      expect(AgentSchedule.fromServerCron('0 0 9-17 * * ?', 0).describe(l),
          'Every hour at :00, 09:00–17:59');
      expect(AgentSchedule.fromServerCron('0 0,30 9-18 * * ?', 0).describe(l),
          'Every 30 minutes, 09:00–18:59');
      expect(AgentSchedule.fromServerCron('0 0 8 ? * MON', 0).describe(l), 'Mon at 08:00');
      expect(AgentSchedule.fromServerCron('0 0 9 * * ?', 0).describe(l), 'Daily at 09:00');
      expect(AgentSchedule.fromServerCron('0 * * * * ?', 0).kind, ScheduleKind.custom);
    });

    test('server time is shown in local time', () {
      // a UTC server running at 02:00 is 09:00 in Bangkok
      expect(AgentSchedule.fromServerCron('0 0 2 * * ?', bangkokOnUtc).describe(l),
          'Daily at 09:00');
      expect(
          AgentSchedule.fromServerCron('0 0 23 ? * MON-THU,SUN', bangkokOnUtc).describe(l),
          'Mon–Fri at 06:00');
    });

    test('anything else is custom', () {
      final s = AgentSchedule.fromServerCron('0 0 12 1/2 * ?', 0);
      expect(s.kind, ScheduleKind.custom);
      expect(s.describe(l), 'Custom: 0 0 12 1/2 * ? (server time)');
    });
  });

  test('day names', () {
    expect(AgentSchedule.daysText({1, 2, 3, 4, 5}), 'Mon–Fri');
    expect(AgentSchedule.daysText({6, 7}), 'Sat, Sun');
    expect(AgentSchedule.daysText({1, 3, 4, 5, 7}), 'Mon, Wed–Fri, Sun');
  });
}
