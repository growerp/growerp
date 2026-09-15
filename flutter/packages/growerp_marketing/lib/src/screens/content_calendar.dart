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

import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';
import '../bloc/social_post_state.dart';
import 'social_post_detail_screen.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// Period the calendar shows at once.
enum CalendarPeriod { week, month }

/// Shows every scheduled social post on a calendar.
///
/// The posts themselves are published by the backend job
/// (`publish#ScheduledSocialPosts`, every 15 minutes) once their master piece
/// is approved; this screen is the view on that schedule, and the place to move
/// a post to another day.
class ContentCalendar extends StatefulWidget {
  const ContentCalendar({super.key});

  @override
  ContentCalendarState createState() => ContentCalendarState();
}

class ContentCalendarState extends State<ContentCalendar> {
  late SocialPostBloc _socialPostBloc;
  CalendarPeriod _period = CalendarPeriod.month;

  /// First day of the shown period, local time, at midnight.
  late DateTime _periodStart;

  /// Below this width the 7-column grid is unreadable, so the same data is
  /// shown as an agenda instead.
  static const double _gridMinWidth = 600;

  @override
  void initState() {
    super.initState();
    _periodStart = _startOf(_period, DateTime.now());
    _socialPostBloc = context.read<SocialPostBloc>();
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
    _socialPostBloc.add(
      SocialPostFetchWindow(from: _gridStart, thru: _periodEnd),
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
    setState(() {
      _period = period;
      _periodStart = _startOf(period, _periodStart);
    });
    _load();
  }

  /// Posts of the period, grouped by the local day they are scheduled on.
  Map<DateTime, List<SocialPost>> _byDay(List<SocialPost> posts) {
    final grouped = <DateTime, List<SocialPost>>{};
    for (final post in posts) {
      final scheduled = post.scheduledDate;
      if (scheduled == null) continue;
      final local = scheduled.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(day, () => []).add(post);
    }
    return grouped;
  }

  Future<void> _openPost(SocialPost post) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (_) => BlocProvider.value(
        value: _socialPostBloc,
        child: SocialPostDetailScreen(socialPost: post),
      ),
    );
    _load();
  }

  /// Opens an empty post already scheduled on [day]; without a postId the
  /// detail screen creates instead of updates.
  Future<void> _addPostOn(DateTime? day) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (_) => BlocProvider.value(
        value: _socialPostBloc,
        child: SocialPostDetailScreen(
          socialPost: day == null
              ? null
              : SocialPost(
                  // the detail screen's own defaults; it creates rather than
                  // updates because there is no postId
                  type: 'PAIN',
                  status: 'DRAFT',
                  scheduledDate:
                      DateTime(day.year, day.month, day.day, _defaultHour),
                ),
        ),
      ),
    );
    _load();
  }

  /// Matches the detail screen's default, so a post added from a day cell and
  /// one added from the dialog land at the same time.
  static const int _defaultHour = 10;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SocialPostBloc, SocialPostState>(
      listener: (context, state) {
        if (state.calendarStatus == SocialPostStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        final posts = state.calendarPosts;
        final loading = state.calendarStatus == SocialPostStatus.loading;
        // one flat index over the period, so a post keeps the same key in the
        // grid and in the agenda
        final indexOfPost = <String?, int>{
          for (var i = 0; i < posts.length; i++) posts[i].postId: i,
        };

        return Scaffold(
          key: const Key('contentCalendar'),
          floatingActionButton: FloatingActionButton(
            key: const Key('addNewCalendarPost'),
            heroTag: 'contentCalendarBtn1',
            tooltip: MarketingLocalizations.of(context)!.contentCalendar,
            onPressed: () => _addPostOn(null),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              _header(context),
              Expanded(
                child: loading && posts.isEmpty
                    ? const _CalendarSkeleton()
                    : LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth < _gridMinWidth
                                ? _agenda(context, posts, indexOfPost)
                                : _grid(context, posts, indexOfPost),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final localizations = MarketingLocalizations.of(context)!;
    final label = _period == CalendarPeriod.month
        ? DateFormat.yMMMM(Localizations.localeOf(context).toString())
            .format(_periodStart)
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

  Widget _grid(
    BuildContext context,
    List<SocialPost> posts,
    Map<String?, int> indexOfPost,
  ) {
    final grouped = _byDay(posts);
    final today = DateTime.now();
    final days = List.generate(
      _gridDayCount,
      (i) => _gridStart.add(Duration(days: i)),
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
                              posts: grouped[day] ?? const [],
                              indexOfPost: indexOfPost,
                              isToday: _isSameDay(day, today),
                              inPeriod: !day.isBefore(_periodStart) &&
                                  day.isBefore(_periodEnd),
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
    final format =
        DateFormat.E(Localizations.localeOf(context).toString());
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
    required List<SocialPost> posts,
    required Map<String?, int> indexOfPost,
    required bool isToday,
    required bool inPeriod,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key('calendarDay_${_dayKey(day)}'),
      onTap: () => _addPostOn(day),
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
            for (final post in posts)
              _postChip(context, post, indexOfPost[post.postId] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _agenda(
    BuildContext context,
    List<SocialPost> posts,
    Map<String?, int> indexOfPost,
  ) {
    final grouped = _byDay(posts);
    if (grouped.isEmpty) {
      return Center(
        child: Text(MarketingLocalizations.of(context)!.calendarNoPosts),
      );
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
          for (final post in grouped[day]!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _postChip(context, post, indexOfPost[post.postId] ?? 0),
            ),
        ],
      ],
    );
  }

  Widget _postChip(BuildContext context, SocialPost post, int index) {
    final scheduled = post.scheduledDate?.toLocal();
    final time = scheduled == null
        ? ''
        : '${scheduled.hour.toString().padLeft(2, '0')}:'
            '${scheduled.minute.toString().padLeft(2, '0')} ';
    final label =
        '$time${post.platform ?? ''} ${post.headline ?? post.pseudoId ?? ''}'
            .trim();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        key: Key('calendarPost$index'),
        onTap: () => _openPost(post),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor(context, post).withValues(alpha: 0.18),
            border: Border(
              left: BorderSide(color: _statusColor(context, post), width: 3),
            ),
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

  /// A post that failed to publish stays READY and is retried every 15
  /// minutes, so publishError is the only signal that something is stuck.
  Color _statusColor(BuildContext context, SocialPost post) {
    if ((post.publishError ?? '').isNotEmpty) return Colors.red;
    switch (post.status) {
      case 'PUBLISHED':
        return Colors.green;
      case 'READY':
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';
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
