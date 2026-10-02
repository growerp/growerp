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

import 'package:intl/intl.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

/// How often an agent runs, as the schedule popup offers it.
enum ScheduleKind { minutes, hourly, daily, monthly, custom }

/// Why a schedule cannot be written as one cron expression in the other time
/// zone.
enum ScheduleError {
  /// Only some weekdays are picked and the runs cross midnight in the other
  /// time zone.
  crossesMidnight,

  /// The day of the month moves past day 28.
  monthEnd,

  /// An hour window with a time zone that is not a whole number of hours away.
  partialHourWindow,
}

/// An agent schedule in one time zone. Agent jobs run in the server's time
/// zone (Quartz cron, see AdkSchedulerServices); the popup edits it in the
/// user's local time. [shift] moves it between the two: server time = local
/// time + delta, delta = serverUtcOffset - localUtcOffset (minutes).
class AgentSchedule {
  final ScheduleKind kind;

  /// minutes kind: every [everyMinutes] (5, 10, 15, 20 or 30), starting at
  /// minute [minuteOffset] of the hour (0 in local time)
  final int everyMinutes;
  final int minuteOffset;

  /// hourly, daily and monthly kinds
  final int minute;

  /// daily and monthly kinds
  final int hour;

  /// minutes and hourly kinds: the hours it runs in, null = all day
  final Set<int>? hours;

  /// weekdays it runs on (1 = Monday … 7 = Sunday); all seven = every day.
  /// Not used by the monthly kind.
  final Set<int> days;

  /// monthly kind: 1–28; 0 = last day of the month (only in server time)
  final int dayOfMonth;

  /// custom kind: a Quartz cron expression in server time
  final String cron;

  static const allDays = {1, 2, 3, 4, 5, 6, 7};
  static const weekdays = {1, 2, 3, 4, 5};
  static const intervals = [5, 10, 15, 20, 30];

  const AgentSchedule({
    required this.kind,
    this.everyMinutes = 30,
    this.minuteOffset = 0,
    this.minute = 0,
    this.hour = 9,
    this.hours,
    this.days = allDays,
    this.dayOfMonth = 1,
    this.cron = '',
  });

  /// The default for a newly scheduled agent: daily at 09:00.
  static const dailyAtNine = AgentSchedule(kind: ScheduleKind.daily);

  AgentSchedule copyWith({
    ScheduleKind? kind,
    int? everyMinutes,
    int? minuteOffset,
    int? minute,
    int? hour,
    Set<int>? hours,
    bool clearHours = false,
    Set<int>? days,
    int? dayOfMonth,
    String? cron,
  }) =>
      AgentSchedule(
        kind: kind ?? this.kind,
        everyMinutes: everyMinutes ?? this.everyMinutes,
        minuteOffset: minuteOffset ?? this.minuteOffset,
        minute: minute ?? this.minute,
        hour: hour ?? this.hour,
        hours: clearHours ? null : (hours ?? this.hours),
        days: days ?? this.days,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        cron: cron ?? this.cron,
      );

  bool get allDaysSelected => days.length == 7;

  /// The window as from/to hours when [hours] is one block of hours, else null.
  (int, int)? get window {
    final h = hours;
    if (h == null || h.isEmpty) return null;
    final sorted = h.toList()..sort();
    if (sorted.last - sorted.first + 1 != sorted.length) return null;
    return (sorted.first, sorted.last);
  }

  /// This schedule moved by [delta] minutes (server = local + delta), or an
  /// error when the result cannot be one cron expression.
  (AgentSchedule?, ScheduleError?) shift(int delta) {
    if (kind == ScheduleKind.custom || delta == 0) return (this, null);
    final deltaM = delta % 60; // 0..59
    final deltaH = (delta - deltaM) ~/ 60;
    switch (kind) {
      case ScheduleKind.daily:
      case ScheduleKind.monthly:
        final total = hour * 60 + minute + delta;
        final dayShift = _floorDiv(total, 1440);
        final t = total % 1440;
        final moved = copyWith(hour: t ~/ 60, minute: t % 60);
        if (kind == ScheduleKind.daily) {
          return (moved.copyWith(days: _shiftDays(days, dayShift)), null);
        }
        final day = (dayOfMonth == 0 ? 0 : dayOfMonth) + dayShift;
        if (dayOfMonth == 0 && dayShift > 0) return (moved.copyWith(dayOfMonth: dayShift), null);
        if (dayOfMonth == 0 && dayShift < 0) return (null, ScheduleError.monthEnd);
        if (day == 0) return (moved.copyWith(dayOfMonth: 0), null);
        if (day > 28) return (null, ScheduleError.monthEnd);
        return (moved.copyWith(dayOfMonth: day), null);
      case ScheduleKind.hourly:
      case ScheduleKind.minutes:
        int hourShift;
        AgentSchedule moved;
        if (kind == ScheduleKind.hourly) {
          final m = minute + deltaM;
          hourShift = deltaH + (m >= 60 ? 1 : 0);
          moved = copyWith(minute: m % 60);
        } else {
          if (deltaM != 0 && (hours != null || !allDaysSelected)) {
            return (null, ScheduleError.partialHourWindow);
          }
          hourShift = deltaH;
          moved = copyWith(minuteOffset: (minuteOffset + deltaM) % everyMinutes);
        }
        final h = hours;
        if (h == null) {
          if (!allDaysSelected && hourShift != 0) {
            return (null, ScheduleError.crossesMidnight);
          }
          return (moved, null);
        }
        final dayShifts = <int>{};
        final newHours = <int>{};
        for (final x in h) {
          final y = x + hourShift;
          dayShifts.add(_floorDiv(y, 24));
          newHours.add(y % 24);
        }
        if (!allDaysSelected) {
          if (dayShifts.length > 1) return (null, ScheduleError.crossesMidnight);
          return (
            moved.copyWith(hours: newHours, days: _shiftDays(days, dayShifts.first)),
            null
          );
        }
        return (moved.copyWith(hours: newHours), null);
      case ScheduleKind.custom:
        return (this, null);
    }
  }

  /// The Quartz cron expression for this schedule in its own time zone.
  String toCron() {
    String dom = '*', dow = '?';
    if (!allDaysSelected && kind != ScheduleKind.monthly) {
      dom = '?';
      dow = _daysField(days);
    }
    final hourField = hours == null ? '*' : _hoursField(hours!);
    switch (kind) {
      case ScheduleKind.minutes:
        final m = minuteOffset == 0 ? '*/$everyMinutes' : '$minuteOffset/$everyMinutes';
        return '0 $m $hourField $dom * $dow';
      case ScheduleKind.hourly:
        return '0 $minute $hourField $dom * $dow';
      case ScheduleKind.daily:
        return '0 $minute $hour $dom * $dow';
      case ScheduleKind.monthly:
        return '0 $minute $hour ${dayOfMonth == 0 ? 'L' : dayOfMonth} * ?';
      case ScheduleKind.custom:
        return cron;
    }
  }

  /// The server-time cron for this local schedule, or an error.
  (String?, ScheduleError?) toServerCron(int delta) {
    final (moved, error) = shift(delta);
    return (moved?.toCron(), error);
  }

  /// A server-time [cron] as a local schedule. Anything the popup cannot show
  /// (or that does not convert exactly) comes back as the custom kind.
  static AgentSchedule fromServerCron(String cron, int delta) {
    final custom = AgentSchedule(kind: ScheduleKind.custom, cron: cron.trim());
    final server = _parse(cron.trim());
    if (server == null) return custom;
    final (local, error) = server.shift(-delta);
    if (local == null || error != null) return custom;
    if (local.kind == ScheduleKind.monthly && local.dayOfMonth == 0) return custom;
    if ((local.kind == ScheduleKind.minutes || local.kind == ScheduleKind.hourly) &&
        local.hours != null &&
        local.window == null) {
      return custom;
    }
    if (local.kind == ScheduleKind.minutes && local.minuteOffset != 0) return custom;
    return local;
  }

  /// Plain-language text, e.g. "Mon–Fri at 08:00".
  String describe(AdkLocalizations l, [String? locale]) {
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(hour)}:${two(minute)}';
    final dayText = allDaysSelected ? null : daysText(days, locale);
    final w = window;
    final windowText = w == null ? null : l.adk_schedWindow('${two(w.$1)}:00', '${two(w.$2)}:59');
    switch (kind) {
      case ScheduleKind.minutes:
        return [l.adk_schedEveryMinutes(everyMinutes), ?windowText, ?dayText].join(', ');
      case ScheduleKind.hourly:
        return [l.adk_schedEveryHour(two(minute)), ?windowText, ?dayText].join(', ');
      case ScheduleKind.daily:
        return dayText == null ? l.adk_schedDaily(time) : l.adk_schedOnDays(dayText, time);
      case ScheduleKind.monthly:
        return l.adk_schedMonthly(dayOfMonth, time);
      case ScheduleKind.custom:
        return l.adk_schedCustom(cron);
    }
  }

  /// Weekday names, contiguous runs as ranges: "Mon–Fri", "Sat, Sun".
  static String daysText(Set<int> days, [String? locale]) {
    // 2024-01-01 is a Monday
    String name(int d) => DateFormat.E(locale).format(DateTime(2024, 1, d));
    final sorted = days.toList()..sort();
    final parts = <String>[];
    var i = 0;
    while (i < sorted.length) {
      var j = i;
      while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
        j++;
      }
      parts.add(j - i >= 2
          ? '${name(sorted[i])}–${name(sorted[j])}'
          : [for (var k = i; k <= j; k++) name(sorted[k])].join(', '));
      i = j + 1;
    }
    return parts.join(', ');
  }

  // ── cron fields ───────────────────────────────────────────────────────────
  static const _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static int _floorDiv(int a, int b) => (a - (a % b)) ~/ b;

  static Set<int> _shiftDays(Set<int> days, int shift) =>
      shift == 0 ? days : {for (final d in days) (d - 1 + shift) % 7 + 1};

  static String _ranges(List<int> sorted, String Function(int) label) {
    final parts = <String>[];
    var i = 0;
    while (i < sorted.length) {
      var j = i;
      while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
        j++;
      }
      parts.add(j > i ? '${label(sorted[i])}-${label(sorted[j])}' : label(sorted[i]));
      i = j + 1;
    }
    return parts.join(',');
  }

  static String _hoursField(Set<int> hours) =>
      _ranges(hours.toList()..sort(), (h) => '$h');

  static String _daysField(Set<int> days) =>
      _ranges(days.toList()..sort(), (d) => _dayNames[d - 1]);

  /// Parses the cron shapes [toCron] writes (plus evenly spaced minute lists
  /// such as "0,30"); null for anything else.
  static AgentSchedule? _parse(String cron) {
    final f = cron.split(RegExp(r'\s+'));
    if (f.length == 7 && f[6] == '*') f.removeLast();
    if (f.length != 6 || f[0] != '0' || f[4] != '*') return null;
    final minF = f[1], hourF = f[2], domF = f[3], dowF = f[5];

    final days = _parseDays(dowF);
    if (days == null) return null;
    final dom = domF == '*' || domF == '?' ? null : (domF == 'L' ? 0 : int.tryParse(domF));
    if (dom == null && !(domF == '*' || domF == '?')) return null;
    if (dom != null && (dom > 28 || days.length != 7)) return null;

    // minute field: a number, or every N minutes
    int? minute = int.tryParse(minF);
    int? every, offset;
    if (minute == null) {
      final step = RegExp(r'^(\*|\d+)/(\d+)$').firstMatch(minF);
      if (step != null) {
        offset = step.group(1) == '*' ? 0 : int.parse(step.group(1)!);
        every = int.parse(step.group(2)!);
      } else if (RegExp(r'^\d+(,\d+)+$').hasMatch(minF)) {
        final mins = minF.split(',').map(int.parse).toList()..sort();
        final n = mins[1] - mins[0];
        final even = [for (var k = 0; k < mins.length; k++) mins[0] + k * n];
        if (even.join(',') != mins.join(',') || mins.length * n != 60) return null;
        offset = mins[0];
        every = n;
      } else {
        return null;
      }
      if (!intervals.contains(every) || offset >= every) return null;
    } else if (minute < 0 || minute > 59) {
      return null;
    }

    // hour field
    Set<int>? hours;
    if (hourF != '*') {
      hours = _parseHours(hourF);
      if (hours == null) return null;
    }

    if (every != null) {
      if (dom != null) return null;
      return AgentSchedule(
          kind: ScheduleKind.minutes,
          everyMinutes: every,
          minuteOffset: offset!,
          hours: hours,
          days: days);
    }
    if (hours != null && hours.length == 1 && hourF == '${hours.first}') {
      if (dom != null) {
        return AgentSchedule(
            kind: ScheduleKind.monthly, minute: minute!, hour: hours.first, dayOfMonth: dom);
      }
      return AgentSchedule(
          kind: ScheduleKind.daily, minute: minute!, hour: hours.first, days: days);
    }
    if (dom != null) return null;
    return AgentSchedule(kind: ScheduleKind.hourly, minute: minute!, hours: hours, days: days);
  }

  static Set<int>? _parseHours(String field) {
    final out = <int>{};
    for (final part in field.split(',')) {
      final r = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(part);
      if (r == null) return null;
      final a = int.parse(r.group(1)!);
      final b = r.group(2) == null ? a : int.parse(r.group(2)!);
      if (a > 23 || b > 23 || b < a) return null;
      for (var h = a; h <= b; h++) {
        out.add(h);
      }
    }
    return out;
  }

  static Set<int>? _parseDays(String field) {
    if (field == '?' || field == '*') return allDays;
    int? day(String s) {
      final i = _dayNames.indexOf(s.toUpperCase());
      if (i >= 0) return i + 1;
      final n = int.tryParse(s); // Quartz numbers: 1 = Sunday … 7 = Saturday
      if (n == null || n < 1 || n > 7) return null;
      return n == 1 ? 7 : n - 1;
    }

    final out = <int>{};
    for (final part in field.split(',')) {
      final r = part.split('-');
      if (r.length > 2) return null;
      final a = day(r[0]);
      final b = r.length == 2 ? day(r[1]) : a;
      if (a == null || b == null || b < a) return null;
      for (var d = a; d <= b; d++) {
        out.add(d);
      }
    }
    return out;
  }
}
