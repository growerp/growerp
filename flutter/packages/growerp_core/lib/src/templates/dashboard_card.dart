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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_models/growerp_models.dart';
import '../domains/domains.dart';

/// Premium dashboard card widget with glassmorphism, gradients, and animations.
/// Features hover effects, icon backgrounds, and smooth transitions.
///
/// Optionally supports:
/// - [actionLabel] and [onAction] for action-oriented quick actions
/// - [stats] for displaying metrics below the title
class DashboardCard extends StatefulWidget {
  final String title;
  final String iconName;
  final String? route;
  final String? stats;
  final int animationIndex;

  /// Optional label for a quick action button (e.g., "View All", "Add New")
  final String? actionLabel;

  /// Callback when the action button is pressed
  final VoidCallback? onAction;

  const DashboardCard({
    super.key,
    required this.title,
    required this.iconName,
    this.route,
    this.stats,
    this.animationIndex = 0,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Staggered entrance animation
    Future.delayed(Duration(milliseconds: 50 * widget.animationIndex), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _isHovered ? 1.05 : 1.0,
              _isHovered ? 1.05 : 1.0,
              1.0,
            ),
            transformAlignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: _isHovered ? 0.3 : 0.1,
                    ),
                    blurRadius: _isHovered ? 20 : 10,
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer.withValues(
                            alpha: isDark ? 0.7 : 0.8,
                          ),
                          colorScheme.secondaryContainer.withValues(
                            alpha: isDark ? 0.5 : 0.6,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: _isHovered ? 0.5 : 0.2,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: widget.route != null
                            ? Key('tap${widget.route}')
                            : null,
                        onTap: widget.route != null
                            ? () => context.go(widget.route!)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        splashColor: colorScheme.primary.withValues(alpha: 0.2),
                        highlightColor: colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 10.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon with circular gradient background
                              Flexible(
                                flex: isAPhone(context) ? 1 : 2,
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isAPhone(context) ? 8 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        colorScheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        colorScheme.primary.withValues(
                                          alpha: 0.05,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: IconTheme(
                                      data: IconThemeData(
                                        color: colorScheme.primary,
                                        size: 32,
                                      ),
                                      child:
                                          getIconFromRegistry(
                                            widget.iconName,
                                          ) ??
                                          const Icon(Icons.dashboard),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Title with gradient text effect
                              Flexible(
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      colorScheme.onSurface,
                                      colorScheme.onSurface.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  ).createShader(bounds),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isAPhone(context)
                                          ? widget.title.replaceFirst(' ', '\n')
                                          : widget.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isAPhone(context) ? 13 : 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.stats != null &&
                                  !isAPhone(context)) ...[
                                const SizedBox(height: 4),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.stats!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                            fontSize: 11,
                                          ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                              ],
                              // Optional action button for quick actions
                              if (widget.actionLabel != null &&
                                  !isAPhone(context)) ...[
                                const SizedBox(height: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onAction,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        widget.actionLabel!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
class DashboardGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const DashboardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.primaryContainer.withValues(alpha: isDark ? 0.15 : 0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isAPhone(context) ? 160 : 200,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
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
