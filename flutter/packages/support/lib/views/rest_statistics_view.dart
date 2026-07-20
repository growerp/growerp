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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

/// Dot plot of per-user REST activity: one row per user, one column per day,
/// a dot where the user made at least one REST call that day. Dot size and
/// color intensity encode the call count (log scaled).
class RestStatisticsView extends StatefulWidget {
  const RestStatisticsView({super.key});

  @override
  State<RestStatisticsView> createState() => _RestStatisticsViewState();
}

class _RestStatisticsViewState extends State<RestStatisticsView> {
  static const double _nameWidth = 150;
  static const double _cellWidth = 20;
  static const double _rowHeight = 26;

  late RestClient _restClient;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  RestUsageStatistics? _stats;
  bool _loading = true;
  String? _error;
  int _periodDays = 30;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<RestClient>();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final stats = await _restClient.getRestUsageStatistics(
        startDateTime:
            '${_dateFormat.format(now.subtract(Duration(days: _periodDays)))} 00:00:00',
        endDateTime: '${_dateFormat.format(now)} 23:59:59',
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<DateTime> _dayColumns() {
    final stats = _stats!;
    final from = DateTime.parse(stats.fromDate);
    final thru = DateTime.parse(stats.thruDate);
    final days = <DateTime>[];
    for (var d = from;
        !d.isAfter(thru);
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  int _maxDayCount() {
    var max = 1;
    for (final user in _stats!.users) {
      for (final day in user.days) {
        if (day.hitCount > max) max = day.hitCount;
      }
    }
    return max;
  }

  Widget _headerRow(List<DateTime> days) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        const SizedBox(width: _nameWidth),
        for (var i = 0; i < days.length; i++)
          SizedBox(
            width: _cellWidth,
            child: Column(
              children: [
                Text(
                  i == 0 || days[i].day == 1
                      ? DateFormat('MMM').format(days[i])
                      : '',
                  style: textStyle?.copyWith(fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
                Text('${days[i].day}',
                    style: textStyle?.copyWith(fontSize: 9)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _userRow(int index, RestUsageUser user, List<DateTime> days,
      int maxCount) {
    final dayCounts = {for (final d in user.days) d.day: d.hitCount};
    final name = [user.firstName, user.lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    final label = name.isNotEmpty ? name : (user.loginName ?? user.userId);
    final primary = Theme.of(context).colorScheme.primary;
    final logMax = math.log(maxCount + 1);
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _nameWidth,
            child: Tooltip(
              message: '$label\n'
                  'login: ${user.loginName ?? ''}\n'
                  'company: ${user.companyName ?? ''}\n'
                  'total calls: ${user.totalHits}',
              child: Text(
                label,
                key: Key('userRow$index'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          for (final day in days)
            SizedBox(
              width: _cellWidth,
              child: Builder(builder: (context) {
                final count = dayCounts[_dateFormat.format(day)];
                if (count == null) return const SizedBox.shrink();
                // log scale: intensity 0..1 relative to busiest day on screen
                final intensity = math.log(count + 1) / logMax;
                return Tooltip(
                  message: '${_dateFormat.format(day)}: $count calls',
                  child: Center(
                    child: Container(
                      width: 6 + 8 * intensity,
                      height: 6 + 8 * intensity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            primary.withValues(alpha: 0.35 + 0.65 * intensity),
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      key: const Key('RestStatisticsView'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('User REST activity '
                              '${stats!.fromDate} — ${stats.thruDate}'),
                          const SizedBox(width: 20),
                          DropdownButton<int>(
                            key: const Key('periodDropDown'),
                            value: _periodDays,
                            items: const [
                              DropdownMenuItem(
                                  value: 30, child: Text('30 days')),
                              DropdownMenuItem(
                                  value: 60, child: Text('60 days')),
                              DropdownMenuItem(
                                  value: 90, child: Text('90 days')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              _periodDays = value;
                              _fetch();
                            },
                          ),
                          const SizedBox(width: 20),
                          Text('${stats.users.length} users'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: stats.users.isEmpty
                            ? const Center(
                                child: Text('No REST activity in period'))
                            : _dotGrid(stats),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _dotGrid(RestUsageStatistics stats) {
    final days = _dayColumns();
    final maxCount = _maxDayCount();
    final totalWidth = _nameWidth + days.length * _cellWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            _headerRow(days),
            const Divider(height: 4),
            Expanded(
              child: ListView.builder(
                key: const Key('listView'),
                itemCount: stats.users.length,
                itemBuilder: (context, index) =>
                    _userRow(index, stats.users[index], days, maxCount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
