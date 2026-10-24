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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

/// Period the calendar shows at once.
enum CalendarPeriod { week, month }

/// Opens the in-app calendar of the logged in user (app bar button).
Future<void> showAppCalendar(BuildContext context) => showDialog(
  barrierDismissible: true,
  context: context,
  builder: (context) => BlocProvider(
    create: (context) => CalendarBloc(context.read<RestClient>()),
    child: const AppCalendarDialog(),
  ),
);

class AppCalendarDialog extends StatelessWidget {
  const AppCalendarDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      key: const Key('AppCalendarDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: CoreLocalizations.of(context)!.calendar,
        height: size.height * 0.9,
        width: isPhone(context) ? size.width : 1100,
        child: const AppCalendar(),
      ),
    );
  }
}

/// One calendar for everything with a date: the events of the connected
/// calendar (or, not connected, the user's todos and events) and, in apps with
/// marketing, the social posts. Activities and posts open in their own dialog
/// when the app registers it ('ActivityDialog', 'SocialPostDialog').
class AppCalendar extends StatefulWidget {
  const AppCalendar({super.key});

  @override
  AppCalendarState createState() => AppCalendarState();
}

class AppCalendarState extends State<AppCalendar> {
  late CalendarBloc _calendarBloc;
  CalendarPeriod _period = CalendarPeriod.month;

  /// First day of the shown period, local time, at midnight.
  late DateTime _periodStart;

  /// Sources switched off with the filter chips.
  final Set<CalendarItemSource> _hidden = {};

  /// Below this width the 7-column grid is unreadable, so the same data is
  /// shown as an agenda instead.
  static const double _gridMinWidth = 600;

  /// Matches the post detail screen's default hour.
  static const int _defaultHour = 10;

  bool get _hasActivityDialog => WidgetRegistry.hasWidget('ActivityDialog');
  bool get _hasPostDialog => WidgetRegistry.hasWidget('SocialPostDialog');

  @override
  void initState() {
    super.initState();
    _periodStart = _startOf(_period, DateTime.now());
    _calendarBloc = context.read<CalendarBloc>();
    _load();
  }

  DateTime _startOf(CalendarPeriod period, DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return period == CalendarPeriod.month
        ? DateTime(date.year, date.month, 1)
        : date.subtract(Duration(days: date.weekday - 1));
  }

  /// Exclusive end of the shown period.
  DateTime get _periodEnd => _period == CalendarPeriod.month
      ? DateTime(_periodStart.year, _periodStart.month + 1, 1)
      : _periodStart.add(const Duration(days: 7));

  /// First day of the grid: the Monday on or before the period start, so a
  /// month always begins on a full week row.
  DateTime get _gridStart =>
      _periodStart.subtract(Duration(days: _periodStart.weekday - 1));

  int get _gridDayCount {
    final days = _periodEnd.difference(_gridStart).inDays;
    return ((days + 6) ~/ 7) * 7;
  }

  void _load() {
    _calendarBloc.add(
      CalendarFetch(
        from: _gridStart,
        thru: _periodEnd,
        includeContent: _hasPostDialog,
      ),
    );
  }

  void _moveTo(DateTime start) {
    setState(() => _periodStart = _startOf(_period, start));
    _load();
  }

  void _shift(int direction) {
    _moveTo(
      _period == CalendarPeriod.month
          ? DateTime(_periodStart.year, _periodStart.month + direction, 1)
          : _periodStart.add(Duration(days: 7 * direction)),
    );
  }

  void _setPeriod(CalendarPeriod period) {
    // stay on today when it is shown, else on the start of what is shown
    final now = DateTime.now();
    final anchor = !now.isBefore(_periodStart) && now.isBefore(_periodEnd)
        ? now
        : _periodStart;
    setState(() {
      _period = period;
      _periodStart = _startOf(period, anchor);
    });
    _load();
  }

  /// Items grouped by their local day; an item spanning several days shows on
  /// each of them.
  Map<DateTime, List<CalendarItem>> _byDay(List<CalendarItem> items) {
    final grouped = <DateTime, List<CalendarItem>>{};
    for (final item in items) {
      final start = item.startLocal;
      if (start == null) continue;
      var day = DateTime(start.year, start.month, start.day);
      final end = item.endLocal;
      // all-day ends are exclusive, timed ends are on their own day
      final last = end == null
          ? day
          : item.allDay
          ? DateTime(end.year, end.month, end.day - 1)
          : DateTime(end.year, end.month, end.day);
      do {
        grouped.putIfAbsent(day, () => []).add(item);
        day = DateTime(day.year, day.month, day.day + 1);
      } while (!day.isAfter(last) && day.isBefore(_periodEnd));
    }
    return grouped;
  }

  Future<void> _open(Widget dialog) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (_) => dialog,
    );
    if (mounted) _load();
  }

  void _openItem(CalendarItem item) {
    if (item.activityId != null && _hasActivityDialog) {
      _open(
        WidgetRegistry.getWidget('ActivityDialog', {
          'activityId': item.activityId,
        }),
      );
    } else if (item.postId != null && _hasPostDialog) {
      _open(
        WidgetRegistry.getWidget('SocialPostDialog', {'postId': item.postId}),
      );
    } else {
      showDialog(
        barrierDismissible: true,
        context: context,
        builder: (_) => _CalendarItemDialog(item: item),
      );
    }
  }

  /// What can be added on [day]; null [day] means without a date.
  List<(String, IconData, Widget)> _addOptions(DateTime? day) {
    final localizations = CoreLocalizations.of(context)!;
    return [
      if (_hasActivityDialog)
        (
          localizations.calendarNewActivity,
          Icons.task_alt,
          WidgetRegistry.getWidget('ActivityDialog', {
            'activityType': 'todo',
            'startDate': ?day,
          }),
        ),
      if (_hasPostDialog)
        (
          localizations.calendarNewPost,
          Icons.share,
          WidgetRegistry.getWidget('SocialPostDialog', {
            if (day != null)
              'scheduledDate': DateTime(
                day.year,
                day.month,
                day.day,
                _defaultHour,
              ),
          }),
        ),
    ];
  }

  Future<void> _addOn(DateTime? day) async {
    final options = _addOptions(day);
    if (options.isEmpty) return;
    if (options.length == 1) return _open(options.first.$3);
    final chosen = await showModalBottomSheet<Widget>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++)
              ListTile(
                key: Key('calendarAdd$i'),
                leading: Icon(options[i].$2),
                title: Text(options[i].$1),
                onTap: () => Navigator.of(context).pop(options[i].$3),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) await _open(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarBloc, CalendarState>(
      listener: (context, state) {
        if (state.status == CalendarStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        final visible = [
          for (final item in state.items)
            if (!_hidden.contains(item.source)) item,
        ];
        // a post with no date belongs to no day: the backlog
        final dated = [
          for (final i in visible)
            if (i.startLocal != null) i,
        ];
        final backlog = [
          for (final i in visible)
            if (i.startLocal == null) i,
        ];
        // one flat index over the dated items, so an item keeps the same key
        // in the grid and in the agenda
        final indexOfItem = <CalendarItem, int>{
          for (var i = 0; i < dated.length; i++) dated[i]: i,
        };
        final canAdd = _hasActivityDialog || _hasPostDialog;

        return Scaffold(
          key: const Key('appCalendar'),
          backgroundColor: Colors.transparent,
          floatingActionButton: canAdd
              ? FloatingActionButton(
                  key: const Key('addNewCalendarItem'),
                  heroTag: 'appCalendarBtn1',
                  onPressed: () => _addOn(null),
                  child: const Icon(Icons.add),
                )
              : null,
          body: Column(
            children: [
              _header(context),
              _filters(context, state),
              if (backlog.isNotEmpty) _backlog(context, backlog),
              Expanded(
                child:
                    state.status == CalendarStatus.loading &&
                        state.items.isEmpty
                    ? const _CalendarSkeleton()
                    : LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth < _gridMinWidth
                            ? _agenda(context, dated, indexOfItem)
                            : _grid(context, dated, indexOfItem, canAdd),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    final label = _period == CalendarPeriod.month
        ? DateFormat.yMMMM(
            Localizations.localeOf(context).toString(),
          ).format(_periodStart)
        : '${_periodStart.toLocalizedShortDate(context)} - '
              '${_periodEnd.subtract(const Duration(days: 1)).toLocalizedShortDate(context)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          IconButton(
            key: const Key('calendarPrev'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shift(-1),
          ),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            key: const Key('calendarNext'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shift(1),
          ),
          TextButton(
            key: const Key('calendarToday'),
            onPressed: () => _moveTo(DateTime.now()),
            child: Text(localizations.calendarToday),
          ),
          SegmentedButton<CalendarPeriod>(
            key: const Key('calendarPeriod'),
            segments: [
              ButtonSegment(
                value: CalendarPeriod.week,
                label: Text(localizations.calendarWeek),
              ),
              ButtonSegment(
                value: CalendarPeriod.month,
                label: Text(localizations.calendarMonth),
              ),
            ],
            selected: {_period},
            onSelectionChanged: (selected) => _setPeriod(selected.first),
          ),
        ],
      ),
    );
  }

  /// One chip per source present, plus the hint to connect a calendar when
  /// the activities are shown in its place.
  Widget _filters(BuildContext context, CalendarState state) {
    final localizations = CoreLocalizations.of(context)!;
    final sources = [
      state.calendarConnected
          ? CalendarItemSource.calendar
          : CalendarItemSource.activity,
      if (_hasPostDialog) CalendarItemSource.socialPost,
    ];
    String label(CalendarItemSource source) => switch (source) {
      CalendarItemSource.calendar => localizations.calendarSourceCalendar,
      CalendarItemSource.activity => localizations.calendarSourceActivities,
      CalendarItemSource.socialPost => localizations.calendarSourcePosts,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          for (final source in sources)
            FilterChip(
              key: Key('calendarFilter_${source.name}'),
              avatar: CircleAvatar(
                backgroundColor: _sourceColor(context, source),
                radius: 6,
              ),
              label: Text(label(source)),
              // the dot is the legend: a checkmark would cover it
              showCheckmark: false,
              selected: !_hidden.contains(source),
              onSelected: (on) => setState(
                () => on ? _hidden.remove(source) : _hidden.add(source),
              ),
            ),
          if (!state.calendarConnected &&
              state.status == CalendarStatus.success)
            TextButton.icon(
              key: const Key('calendarConnect'),
              icon: const Icon(Icons.link, size: 16),
              label: Text(localizations.calendarConnectHint),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => const GoogleWorkspaceSettingsDialog(),
                );
                if (mounted) _load();
              },
            ),
        ],
      ),
    );
  }

  /// Posts with no date at all. They are invisible on a calendar otherwise, and
  /// they never publish either: the scheduler only picks up posts it can place.
  Widget _backlog(BuildContext context, List<CalendarItem> backlog) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('calendarBacklog'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CoreLocalizations.of(context)!.calendarBacklog(backlog.length),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: backlog.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = backlog[index];
                return ActionChip(
                  key: Key('calendarBacklogItem$index'),
                  avatar: const Icon(Icons.schedule, size: 16),
                  label: Text(item.title, overflow: TextOverflow.ellipsis),
                  onPressed: () => _openItem(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    List<CalendarItem> items,
    Map<CalendarItem, int> indexOfItem,
    bool canAdd,
  ) {
    final grouped = _byDay(items);
    final today = DateTime.now();
    final days = List.generate(
      _gridDayCount,
      (i) => DateTime(_gridStart.year, _gridStart.month, _gridStart.day + i),
    );

    return Column(
      children: [
        _weekdayHeader(context),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('listView'),
            child: Column(
              children: [
                for (var row = 0; row < days.length ~/ 7; row++)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final day in days.skip(row * 7).take(7))
                          Expanded(
                            child: _dayCell(
                              context,
                              day: day,
                              items: grouped[day] ?? const [],
                              indexOfItem: indexOfItem,
                              isToday: _isSameDay(day, today),
                              inPeriod:
                                  !day.isBefore(_periodStart) &&
                                  day.isBefore(_periodEnd),
                              canAdd: canAdd,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _weekdayHeader(BuildContext context) {
    final format = DateFormat.E(Localizations.localeOf(context).toString());
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  format.format(_gridStart.add(Duration(days: i))),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dayCell(
    BuildContext context, {
    required DateTime day,
    required List<CalendarItem> items,
    required Map<CalendarItem, int> indexOfItem,
    required bool isToday,
    required bool inPeriod,
    required bool canAdd,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key('calendarDay_${_dayKey(day)}'),
      onTap: canAdd ? () => _addOn(day) : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor, width: 0.5),
          color: inPeriod ? null : theme.disabledColor.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? theme.colorScheme.primary : null,
              ),
            ),
            for (final item in items)
              _itemChip(context, item, indexOfItem[item] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _agenda(
    BuildContext context,
    List<CalendarItem> items,
    Map<CalendarItem, int> indexOfItem,
  ) {
    final grouped = _byDay(items);
    if (grouped.isEmpty) {
      return Center(child: Text(CoreLocalizations.of(context)!.calendarEmpty));
    }
    final days = grouped.keys.toList()..sort();

    return ListView(
      key: const Key('listView'),
      children: [
        for (final day in days) ...[
          Padding(
            key: Key('calendarDay_${_dayKey(day)}'),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              day.toLocalizedDateOnly(context),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final item in grouped[day]!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _itemChip(context, item, indexOfItem[item] ?? 0),
            ),
        ],
      ],
    );
  }

  Widget _itemChip(BuildContext context, CalendarItem item, int index) {
    final start = item.startLocal;
    final time = item.allDay || start == null
        ? ''
        : '${start.hour.toString().padLeft(2, '0')}:'
              '${start.minute.toString().padLeft(2, '0')} ';
    final label = '$time${item.platform ?? ''} ${item.title}'.trim();
    final color = _itemColor(context, item);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        key: Key('calendarItem$index'),
        onTap: () => _openItem(item),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Color _sourceColor(BuildContext context, CalendarItemSource? source) =>
      switch (source) {
        CalendarItemSource.socialPost => Colors.orange,
        CalendarItemSource.activity => Colors.teal,
        _ => Theme.of(context).colorScheme.primary,
      };

  /// Posts keep their status colors: a post that failed to publish stays
  /// READY and is retried, so publishError is the only signal it is stuck.
  Color _itemColor(BuildContext context, CalendarItem item) {
    if (item.source != CalendarItemSource.socialPost) {
      return _sourceColor(context, item.source);
    }
    if ((item.publishError ?? '').isNotEmpty) return Colors.red;
    return switch (item.statusId) {
      'PUBLISHED' => Colors.green,
      'READY' => Colors.orange,
      _ => Colors.grey,
    };
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Read-only view of a calendar event that has no GrowERP record behind it.
class _CalendarItemDialog extends StatelessWidget {
  const _CalendarItemDialog({required this.item});

  final CalendarItem item;

  @override
  Widget build(BuildContext context) {
    final start = item.startLocal;
    final end = item.endLocal;
    String format(DateTime d) => item.allDay
        ? d.toLocalizedDateOnly(context)
        : '${d.toLocalizedDateOnly(context)} '
              '${d.hour.toString().padLeft(2, '0')}:'
              '${d.minute.toString().padLeft(2, '0')}';
    return Dialog(
      key: const Key('CalendarItemDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: item.title,
        height: 350,
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.calendarName.isNotEmpty)
                Text(
                  item.calendarName,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              if (start != null)
                Text(
                  // an all-day end is exclusive: show the last day
                  end == null
                      ? format(start)
                      : '${format(start)} - ${format(item.allDay ? end.subtract(const Duration(days: 1)) : end)}',
                  key: const Key('calendarItemTime'),
                ),
              const SizedBox(height: 12),
              Text(item.description),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SkeletonLoader(width: double.infinity, height: 80),
      ),
    );
  }
}
