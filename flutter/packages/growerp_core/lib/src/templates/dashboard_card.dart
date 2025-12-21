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
import 'package:go_router/go_router.dart';
import 'package:growerp_models/growerp_models.dart';
import '../domains/domains.dart';

/// Reusable dashboard card widget for displaying menu options with statistics.
/// This widget is designed to be used across all apps that display a dashboard
/// with menu option cards.
class DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String? route;
  final String? stats;

  const DashboardCard({
    super.key,
    required this.title,
    required this.iconName,
    this.route,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
      elevation: 4,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: route != null ? Key('tap$route') : null,
        onTap: route != null ? () => context.go(route!) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child:
                      getIconFromRegistry(iconName) ??
                      const Icon(Icons.dashboard, size: 28),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stats != null) ...[
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    stats!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable dashboard grid widget that provides consistent compact layout.
/// This widget handles the grid configuration for dashboard cards across all apps.
///
/// Usage:
/// ```dart
/// DashboardGrid(
///   itemCount: menuItems.length,
///   itemBuilder: (context, index) => DashboardCard(
///     title: menuItems[index].title,
///     iconName: menuItems[index].iconName,
///     route: menuItems[index].route,
///   ),
/// )
/// ```
class DashboardGrid extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const DashboardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid>
    with SingleTickerProviderStateMixin {
  // Static flag to ensure overlay only shows once per app session
  static bool _hasShownOverlay = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Only show overlay if it hasn't been shown yet this session
    if (!_hasShownOverlay) {
      _hasShownOverlay = true;
      _showOverlay = true;

      // Start fade out after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _fadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _showOverlay = false;
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isAPhone(context) ? 154 : 198,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
          ),
        ),
        // Temporary instructional overlay (card style)
        if (_showOverlay)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.30,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Add Your Own Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'With the ☰ menu button you can add your own menu items',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Maps menu option routes to their corresponding statistics from the Stats model.
///
/// This utility function provides a consistent mapping across all dashboard
/// implementations. Returns null if no matching stats are found for the route.
///
/// Usage:
/// ```dart
/// final stats = authState.authenticate?.stats;
/// final statsText = getStatsForRoute(option.route, stats);
/// ```
String? getStatsForRoute(String? route, Stats? stats) {
  if (stats == null || route == null) return null;

  switch (route) {
    case '/orders':
      return 'Sales: ${stats.openSlsOrders}\nPurchase: ${stats.openPurOrders}';
    case '/accounting':
      return 'Sales Invoices: ${stats.salesInvoicesNotPaidCount}\nPurchase: ${stats.purchInvoicesNotPaidCount}';
    case '/shipments':
      return 'Incoming: ${stats.incomingShipments}\nOutgoing: ${stats.outgoingShipments}';
    case '/inventory':
      return 'WH Locations: ${stats.whLocations}';
    case '/requests':
      return 'Requests: ${stats.requests}';
    case '/catalog':
      return 'Categories: ${stats.categories}\nProducts: ${stats.products}';
    case '/crm':
      return 'Customers: ${stats.customers}\nLeads: ${stats.leads}\nSuppliers: ${stats.suppliers}';
    case '/users':
      return 'Admins: ${stats.admins}\nEmployees: ${stats.employees}';
    case '/opportunities':
      return 'Opportunities: ${stats.opportunities}';
    case '/tasks':
      return 'Tasks: ${stats.allTasks}\nHours: ${stats.notInvoicedHours}';
    case '/activities':
      return 'To Do: ${stats.todoActivities}\nEvents: ${stats.eventActivities}';
    case '/assets':
      return 'Assets: ${stats.assets}';
    default:
      return null;
  }
}
