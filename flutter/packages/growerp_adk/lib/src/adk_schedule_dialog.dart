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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

import 'adk_config_service.dart';
import 'adk_schedule.dart';

/// Minutes to add to local time to get server time.
int scheduleDelta(AdkSchedulePreview server) =>
    server.serverUtcOffsetMinutes - DateTime.now().timeZoneOffset.inMinutes;

String _utcOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final m = minutes.abs();
  return 'UTC$sign${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// The server-time cron of a new schedule: daily at 09:00 local time.
Future<String> defaultScheduleCron() async {
  try {
    final delta = scheduleDelta(await AdkConfigService.serverTime());
    return AgentSchedule.dailyAtNine.toServerCron(delta).$1!;
  } catch (_) {
    return AgentSchedule.dailyAtNine.toCron();
  }
}

/// A stored (server-time) cron as plain text in the user's local time, with
/// the cron itself as tooltip. Falls back to the cron while the server time
/// zone is unknown.
class ScheduleText extends StatelessWidget {
  final String cron;
  final TextStyle? style;
  const ScheduleText(this.cron, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return FutureBuilder<AdkSchedulePreview>(
      future: AdkConfigService.serverTime(),
      builder: (context, snap) {
        final text = snap.hasData
            ? AgentSchedule.fromServerCron(cron, scheduleDelta(snap.data!))
                .describe(l, locale)
            : cron;
        return Tooltip(
          message: cron,
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}

/// Popup to pick an agent's schedule in plain terms, in the user's local
/// time. Returns the server-time cron, or null when cancelled.
class AdkScheduleDialog extends StatefulWidget {
  final String? cron;
  const AdkScheduleDialog({super.key, this.cron});

  static Future<String?> show(BuildContext context, {String? cron}) =>
      showDialog<String>(
        context: context,
        builder: (_) => AdkScheduleDialog(cron: cron),
      );

  @override
  State<AdkScheduleDialog> createState() => _AdkScheduleDialogState();
}

class _AdkScheduleDialogState extends State<AdkScheduleDialog> {
  AdkSchedulePreview? _server;
  int _delta = 0;
  AgentSchedule _s = AgentSchedule.dailyAtNine;
  final _cronCtrl = TextEditingController();
  AdkSchedulePreview? _preview;
  Timer? _debounce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _server = await AdkConfigService.serverTime();
      _delta = scheduleDelta(_server!);
    } catch (_) {
      // unknown server zone: edit in server time
    }
    final cron = widget.cron?.trim() ?? '';
    final s = cron.isEmpty
        ? AgentSchedule.dailyAtNine
        : AgentSchedule.fromServerCron(cron, _delta);
    if (!mounted) return;
    setState(() {
      _s = s;
      _cronCtrl.text = s.kind == ScheduleKind.custom ? s.cron : (s.toServerCron(_delta).$1 ?? '');
      _loading = false;
    });
    _refreshPreview();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cronCtrl.dispose();
    super.dispose();
  }

  (String?, ScheduleError?) get _result => _s.kind == ScheduleKind.custom
      ? (_cronCtrl.text.trim(), null)
      : _s.toServerCron(_delta);

  void _update(AgentSchedule s) {
    setState(() {
      // switching to custom starts from the cron of what was shown
      if (s.kind == ScheduleKind.custom && _s.kind != ScheduleKind.custom) {
        _cronCtrl.text = _result.$1 ?? _cronCtrl.text;
      }
      _s = s;
    });
    _refreshPreview();
  }

  void _refreshPreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final cron = _result.$1;
      if (cron == null || cron.isEmpty) {
        if (mounted) setState(() => _preview = null);
        return;
      }
      try {
        final svc = await AdkConfigService.create();
        final p = await svc.schedulePreview(cron);
        if (mounted && _result.$1 == cron) setState(() => _preview = p);
      } catch (_) {
        if (mounted) setState(() => _preview = null);
      }
    });
  }

  String _errorText(AdkLocalizations l, ScheduleError e) => switch (e) {
        ScheduleError.crossesMidnight => l.adk_schedErrCrossesMidnight,
        ScheduleError.monthEnd => l.adk_schedErrMonthEnd,
        ScheduleError.partialHourWindow => l.adk_schedErrPartialHour,
      };

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final (cron, error) = _result;
    final invalid = _preview?.valid == false;
    final canSave = !_loading && error == null && (cron ?? '').isNotEmpty && !invalid;
    return Dialog(
      key: const Key('AdkScheduleDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: l.adk_schedTitle,
        width: 460,
        height: 640,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kindChips(l),
                          const SizedBox(height: 12),
                          ..._fields(l, locale),
                          const Divider(height: 24),
                          _previewBox(l, locale, error, invalid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const Key('scheduleCancel'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('scheduleSave'),
                        onPressed: canSave ? () => Navigator.of(context).pop(cron) : null,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _kindChips(AdkLocalizations l) {
    final labels = {
      ScheduleKind.minutes: l.adk_schedKindMinutes,
      ScheduleKind.hourly: l.adk_schedKindHourly,
      ScheduleKind.daily: l.adk_schedKindDaily,
      ScheduleKind.monthly: l.adk_schedKindMonthly,
      ScheduleKind.custom: l.adk_schedKindCustom,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final e in labels.entries)
          ChoiceChip(
            key: Key('scheduleKind_${e.key.name}'),
            label: Text(e.value),
            selected: _s.kind == e.key,
            onSelected: (_) => _update(_s.copyWith(kind: e.key)),
          ),
      ],
    );
  }

  List<Widget> _fields(AdkLocalizations l, String locale) {
    String two(int n) => n.toString().padLeft(2, '0');
    final timeButton = OutlinedButton.icon(
      key: const Key('scheduleTime'),
      icon: const Icon(Icons.access_time),
      label: Text('${l.adk_schedTime}: ${two(_s.hour)}:${two(_s.minute)}'),
      onPressed: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: _s.hour, minute: _s.minute),
        );
        if (t != null) _update(_s.copyWith(hour: t.hour, minute: t.minute));
      },
    );
    switch (_s.kind) {
      case ScheduleKind.minutes:
        return [
          DropdownButtonFormField<int>(
            key: const Key('scheduleEvery'),
            initialValue: _s.everyMinutes,
            decoration: InputDecoration(labelText: l.adk_schedKindMinutes),
            items: [
              for (final n in AgentSchedule.intervals)
                DropdownMenuItem(value: n, child: Text(l.adk_schedEveryMinutes(n))),
            ],
            onChanged: (n) => _update(_s.copyWith(everyMinutes: n)),
          ),
          _windowField(l),
          _daysField(l, locale),
        ];
      case ScheduleKind.hourly:
        return [
          DropdownButtonFormField<int>(
            key: const Key('scheduleMinute'),
            initialValue: _s.minute - _s.minute % 5,
            decoration: InputDecoration(labelText: l.adk_schedAtMinute),
            items: [
              for (var m = 0; m < 60; m += 5)
                DropdownMenuItem(value: m, child: Text(':${two(m)}')),
            ],
            onChanged: (m) => _update(_s.copyWith(minute: m)),
          ),
          _windowField(l),
          _daysField(l, locale),
        ];
      case ScheduleKind.daily:
        return [timeButton, const SizedBox(height: 8), _daysField(l, locale)];
      case ScheduleKind.monthly:
        return [
          DropdownButtonFormField<int>(
            key: const Key('scheduleDayOfMonth'),
            initialValue: _s.dayOfMonth.clamp(1, 28),
            decoration: InputDecoration(labelText: l.adk_schedDayOfMonth),
            items: [
              for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (d) => _update(_s.copyWith(dayOfMonth: d)),
          ),
          const SizedBox(height: 8),
          timeButton,
        ];
      case ScheduleKind.custom:
        return [
          TextField(
            key: const Key('scheduleExpression'),
            controller: _cronCtrl,
            decoration: InputDecoration(
              labelText: l.adk_schedCron,
              helperText: l.adk_schedCronHelp,
              hintText: '0 0 9 ? * MON-FRI',
            ),
            onChanged: (_) => _update(_s.copyWith(cron: _cronCtrl.text.trim())),
          ),
        ];
    }
  }

  Widget _windowField(AdkLocalizations l) {
    String two(int n) => n.toString().padLeft(2, '0');
    final w = _s.window;
    return Column(
      children: [
        SwitchListTile(
          key: const Key('scheduleWindow'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.adk_schedOnlyBetween),
          value: w != null,
          onChanged: (on) => _update(on
              ? _s.copyWith(hours: {for (var h = 9; h <= 17; h++) h})
              : _s.copyWith(clearHours: true)),
        ),
        if (w != null)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('scheduleFrom'),
                  initialValue: w.$1,
                  decoration: InputDecoration(labelText: l.adk_schedFrom),
                  items: [
                    for (var h = 0; h <= w.$2; h++)
                      DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
                  ],
                  onChanged: (h) => _update(_s.copyWith(hours: {for (var x = h!; x <= w.$2; x++) x})),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('scheduleTo'),
                  initialValue: w.$2,
                  decoration: InputDecoration(labelText: l.adk_schedTo),
                  items: [
                    for (var h = w.$1; h <= 23; h++)
                      DropdownMenuItem(value: h, child: Text('${two(h)}:59')),
                  ],
                  onChanged: (h) => _update(_s.copyWith(hours: {for (var x = w.$1; x <= h!; x++) x})),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _daysField(AdkLocalizations l, String locale) {
    String name(int d) => DateFormat.E(locale).format(DateTime(2024, 1, d));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(l.adk_schedDays, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var d = 1; d <= 7; d++)
              FilterChip(
                key: Key('scheduleDay$d'),
                label: Text(name(d)),
                selected: _s.days.contains(d),
                onSelected: (on) {
                  final days = {..._s.days};
                  on ? days.add(d) : days.remove(d);
                  if (days.isNotEmpty) _update(_s.copyWith(days: days));
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              key: const Key('scheduleEveryDay'),
              label: Text(l.adk_schedEveryDay),
              onPressed: () => _update(_s.copyWith(days: AgentSchedule.allDays)),
            ),
            ActionChip(
              key: const Key('scheduleWorkdays'),
              label: Text(l.adk_schedWorkdays),
              onPressed: () => _update(_s.copyWith(days: AgentSchedule.weekdays)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _previewBox(AdkLocalizations l, String locale, ScheduleError? error, bool invalid) {
    final cs = Theme.of(context).colorScheme;
    final runs = _preview?.nextRunsLocal ?? const <DateTime>[];
    final fmt = DateFormat('EEE d MMM HH:mm', locale);
    final server = _server;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _s.describe(l, locale),
          key: const Key('scheduleDescription'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_errorText(l, error),
                key: const Key('scheduleError'), style: TextStyle(color: cs.error)),
          ),
        if (invalid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.adk_schedInvalid(_preview?.error ?? ''),
                key: const Key('scheduleError'), style: TextStyle(color: cs.error)),
          ),
        if (runs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l.adk_schedNextRuns, style: const TextStyle(fontWeight: FontWeight.bold)),
          for (var i = 0; i < runs.length; i++)
            Text(fmt.format(runs[i]), key: Key('scheduleNextRun$i')),
        ],
        if (server != null) ...[
          const SizedBox(height: 12),
          Text(
            l.adk_schedTimeZoneNote(
              '${server.serverTimeZone} (${_utcOffset(server.serverUtcOffsetMinutes)})',
              _utcOffset(DateTime.now().timeZoneOffset.inMinutes),
            ),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
