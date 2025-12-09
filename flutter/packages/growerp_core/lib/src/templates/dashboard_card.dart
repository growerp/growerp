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
    return Card(
      elevation: 4,
      child: InkWell(
        key: route != null ? Key('tap$route') : null,
        onTap: route != null ? () => context.go(route!) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child:
                      getIconFromRegistry(iconName) ??
                      const Icon(Icons.dashboard, size: 48),
                ),
              ),
              const SizedBox(height: 8),
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
                const SizedBox(height: 4),
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
