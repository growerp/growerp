/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'support_dashboard_minis.dart';

/// Support dashboard content - displays dashboard tiles for support options.
///
/// Tile sizing is driven by [MenuItem.tileType]:
/// - 'navigation' (default) → 1×1
/// - 'statistic' → 2×1 (shows stats text)
/// - 'graphic' → 2×2 (shows chart widget), 2×1 when in [compactGraphicRoutes]
///
/// All four chart tiles are fed by a single get#SupportDashboard call made here,
/// unlike the block minis in other apps which each fetch their own endpoint.
class SupportDashboardContent extends StatefulWidget {
  const SupportDashboardContent({super.key});

  @override
  State<SupportDashboardContent> createState() =>
      _SupportDashboardContentState();
}

class _SupportDashboardContentState extends State<SupportDashboardContent> {
  SupportDashboard? dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<RestClient>().getSupportDashboard();
      if (mounted) setState(() => dashboard = result);
    } catch (e) {
      debugPrint('support dashboard load failed: $e');
    }
  }

  /// Null while loading or when a section is missing: the tile then stays a
  /// plain navigation square.
  Widget? _chart(String? route) {
    if (dashboard == null) return null;
    switch (route) {
      case '/applications':
        final stats = dashboard!.applications;
        return stats == null
            ? null
            : ApplicationsDashboardChartMini(stats: stats);
      case '/owners':
        final stats = dashboard!.owners;
        return stats == null ? null : OwnersDashboardChartMini(stats: stats);
      case '/llm-usage':
        final stats = dashboard!.llmUsage;
        return stats == null ? null : LlmUsageDashboardChartMini(stats: stats);
      case '/restStatistics':
        final stats = dashboard!.restUsage;
        return stats == null ? null : RestUsageDashboardChartMini(stats: stats);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            final menuConfig = menuState.menuConfiguration;

            if (menuConfig == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final dashboardOptions =
                menuConfig.menuItems
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != null &&
                          option.route != '/' &&
                          option.route != '/about',
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: DashboardGrid(
                items: dashboardOptions,
                stats: stats,
                onToggleMinimize: (id) => context
                    .read<MenuConfigBloc>()
                    .add(MenuItemToggleMinimize(id)),
                onRefresh: () async {
                  context.read<AuthBloc>().add(AuthLoad());
                  await _load();
                },
                compactGraphicRoutes: const {
                  '/applications',
                  '/owners',
                  '/llm-usage',
                  '/restStatistics',
                },
                chartBuilder: _chart,
              ),
            );
          },
        );
      },
    );
  }
}
