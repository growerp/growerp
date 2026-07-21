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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import 'dashboard_card.dart';
import '../domains/common/functions/functions.dart';

/// One labelled proportional bar in a [DashboardMini] funnel.
typedef DashboardBar = ({String label, int count, Color? color});

/// One headline number in the bottom counter row of a [DashboardMini].
typedef DashboardCounter = ({String label, int value});

/// Bars + counters produced by a [DashboardMiniLoader] data loader.
typedef DashboardMiniData = ({
  List<DashboardBar> bars,
  List<DashboardCounter> counters,
});

/// Shared layout for the half-height "compact graphic" dashboard tiles (used
/// via DashboardGrid.compactGraphicRoutes): keeps the top-left corner clear for
/// the DashboardCard icon+title, renders [bars] as a funnel with the [counters]
/// in a row along the bottom, so every rich tile reads as one system.
class DashboardMini extends StatelessWidget {
  const DashboardMini({
    super.key,
    required this.tileKey,
    required this.bars,
    required this.counters,
    this.emptyMessage = 'No data',
  });

  final Key tileKey;
  final List<DashboardBar> bars;
  final List<DashboardCounter> counters;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    Widget counter(DashboardCounter c) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${c.value}', style: Theme.of(context).textTheme.titleMedium),
          Text(c.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    final counterWidgets = [for (final c in counters) counter(c)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        key: tileKey,
        children: [
          // Keep the top-left corner clear: DashboardCard overlays the
          // icon+title there for compact graphic tiles.
          Expanded(
            child: Padding(
              padding: isPhone
                  ? const EdgeInsets.only(top: 36)
                  : const EdgeInsets.only(left: compactGraphicLogoInset),
              child: _bars(context),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: isPhone
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: counterWidgets,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      for (final c in counterWidgets)
                        Expanded(
                          child: FittedBox(fit: BoxFit.scaleDown, child: c),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bars(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (bars.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    int maxCount = 1;
    for (final b in bars) {
      if (b.count > maxCount) maxCount = b.count;
    }
    // Rows share the available height evenly so all bars always fit without
    // scaling, however small the tile gets.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = constraints.maxHeight / bars.length;
        final barHeight = (rowHeight - 4).clamp(4.0, 12.0);
        final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: (rowHeight - 4).clamp(8.0, 12.0),
        );
        return Column(
          children: bars.asMap().entries.map((entry) {
            final index = entry.key;
            final b = entry.value;
            final barColor =
                b.color ??
                colorScheme.primary.withValues(
                  alpha: 1.0 - (index * 0.6 / bars.length),
                );
            return SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      b.label,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: b.count / maxCount,
                          child: Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text('${b.count}', style: labelStyle),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Fetches one REST endpoint and renders the result as a [DashboardMini].
/// Rich dashboard tiles are thin wrappers around this loader.
class DashboardMiniLoader extends StatefulWidget {
  const DashboardMiniLoader({
    super.key,
    required this.tileKey,
    required this.load,
    this.emptyMessage = 'No data',
  });

  final Key tileKey;
  final Future<DashboardMiniData> Function(RestClient) load;
  final String emptyMessage;

  @override
  State<DashboardMiniLoader> createState() => _DashboardMiniLoaderState();
}

class _DashboardMiniLoaderState extends State<DashboardMiniLoader> {
  DashboardMiniData? data;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.load(context.read<RestClient>());
      if (mounted) setState(() => data = d);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return DashboardMini(
      tileKey: widget.tileKey,
      bars: data!.bars,
      counters: data!.counters,
      emptyMessage: widget.emptyMessage,
    );
  }
}
