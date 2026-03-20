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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_models/growerp_models.dart';
import '../domains/domains.dart';

/// Dashboard card widget with glassmorphism, gradients, and animations.
///
/// Supports three tile types (set via [tileType]):
/// - `'navigation'` (default) — icon + title
/// - `'statistic'` — icon + title + [stats] text (wider)
/// - `'graphic'` — icon + title + [chartWidget] (2×2 in grid units)
///
/// When [isMinimized] is true the tile is compact (1×1), greyed, and shows a
/// restore button. The minimize/restore button is always visible in the
/// top-right corner.
class DashboardCard extends StatefulWidget {
  final String title;
  final String iconName;
  final String? route;

  /// Text stats shown for 'statistic' type tiles
  final String? stats;

  /// Chart widget shown for 'graphic' type tiles, provided by the parent
  final Widget? chartWidget;

  /// Tile display type: 'navigation', 'statistic', or 'graphic'
  final String tileType;

  /// Whether this tile is in minimized state (compact, at end of grid)
  final bool isMinimized;

  /// Called when the minimize/restore button is tapped
  final VoidCallback? onToggleMinimize;

  final int animationIndex;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DashboardCard({
    super.key,
    required this.title,
    required this.iconName,
    this.route,
    this.stats,
    this.chartWidget,
    this.tileType = 'navigation',
    this.isMinimized = false,
    this.onToggleMinimize,
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
    final isPhone = isAPhone(context);
    final minimized = widget.isMinimized;

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
              _isHovered ? 1.03 : 1.0,
              _isHovered ? 1.03 : 1.0,
              1.0,
            ),
            transformAlignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (minimized
                            ? colorScheme.outline
                            : colorScheme.primary)
                        .withValues(alpha: _isHovered ? 0.3 : 0.1),
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
                        colors: minimized
                            ? [
                                colorScheme.surfaceContainerHighest.withValues(
                                  alpha: isDark ? 0.4 : 0.5,
                                ),
                                colorScheme.surfaceContainerHighest.withValues(
                                  alpha: isDark ? 0.3 : 0.4,
                                ),
                              ]
                            : [
                                colorScheme.primaryContainer.withValues(
                                  alpha: isDark ? 0.7 : 0.8,
                                ),
                                colorScheme.secondaryContainer.withValues(
                                  alpha: isDark ? 0.5 : 0.6,
                                ),
                              ],
                      ),
                      border: Border.all(
                        color: (minimized
                                ? colorScheme.outline
                                : colorScheme.primary)
                            .withValues(
                              alpha: _isHovered ? 0.5 : (minimized ? 0.15 : 0.2),
                            ),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Main tappable content
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: widget.route != null
                                ? Key('tap${widget.route}')
                                : null,
                            onTap: widget.route != null
                                ? () => context.go(widget.route!)
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            splashColor:
                                colorScheme.primary.withValues(alpha: 0.2),
                            highlightColor:
                                colorScheme.primary.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 28, 10),
                              child: minimized
                                  ? _buildMinimizedContent(
                                      context,
                                      colorScheme,
                                      isPhone,
                                    )
                                  : _buildFullContent(
                                      context,
                                      colorScheme,
                                      isDark,
                                      isPhone,
                                    ),
                            ),
                          ),
                        ),
                        // Minimize / restore button — always visible, top-right
                        if (widget.onToggleMinimize != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onToggleMinimize,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    minimized
                                        ? Icons.open_in_full
                                        : Icons.close_fullscreen,
                                    size: 14,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildMinimizedContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isPhone,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: IconTheme(
              data: IconThemeData(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 24,
              ),
              child:
                  getIconFromRegistry(widget.iconName) ??
                  const Icon(Icons.dashboard),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    bool isPhone,
  ) {
    final isGraphic =
        widget.tileType == 'graphic' && widget.chartWidget != null;
    final isStatistic =
        widget.tileType == 'statistic' && widget.stats != null && !isPhone;

    return Column(
      mainAxisAlignment:
          isGraphic ? MainAxisAlignment.start : MainAxisAlignment.center,
      mainAxisSize: isGraphic ? MainAxisSize.max : MainAxisSize.min,
      children: [
        // Icon
        Flexible(
          flex: isGraphic ? 1 : (isPhone ? 1 : 2),
          child: Container(
            padding: EdgeInsets.all(isPhone ? 8 : 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: IconTheme(
                data: IconThemeData(color: colorScheme.primary, size: 32),
                child:
                    getIconFromRegistry(widget.iconName) ??
                    const Icon(Icons.dashboard),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Title
        Flexible(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                colorScheme.onSurface,
                colorScheme.onSurface.withValues(alpha: 0.8),
              ],
            ).createShader(bounds),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isPhone ? widget.title.replaceFirst(' ', '\n') : widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isPhone ? 13 : 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        // Chart (graphic type)
        if (isGraphic) ...[
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.chartWidget!,
            ),
          ),
        ],
        // Stats text (statistic type)
        if (isStatistic) ...[
          const SizedBox(height: 4),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.stats!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
        // Optional action button
        if (widget.actionLabel != null && !isPhone) ...[
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
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
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
    );
  }
}

/// Responsive staggered dashboard grid with drag-to-reorder support.
///
/// Tile sizes are driven by [MenuItem.tileType]:
/// - `'navigation'` → 1×1
/// - `'statistic'`  → 2×1
/// - `'graphic'`    → 2×2
///
/// Non-minimized tiles can be long-press dragged to reorder. The new order is
/// persisted immediately via [MenuConfigBloc] (optimistic local update + backend
/// call). Minimized tiles at the bottom are not draggable.
class DashboardGrid extends StatefulWidget {
  final List<MenuItem> items;
  final Stats? stats;

  /// Returns a chart widget for the given route, or null if none.
  final Widget? Function(String route)? chartBuilder;

  /// Called when the user taps the minimize/restore button on a tile.
  final void Function(String menuItemId)? onToggleMinimize;

  const DashboardGrid({
    super.key,
    required this.items,
    this.stats,
    this.chartBuilder,
    this.onToggleMinimize,
  });

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  /// Working copy of non-minimized items; reordered optimistically on drop.
  List<MenuItem> _orderedItems = [];

  /// menuItemId of the tile currently being dragged, or null.
  String? _draggingItemId;

  /// menuItemId of the tile currently hovered over as a drop target, or null.
  String? _hoverTargetId;

  /// Grid column width in logical pixels, updated by LayoutBuilder.
  double _colWidth = 100;

  @override
  void initState() {
    super.initState();
    _orderedItems = widget.items.where((m) => !m.isMinimized).toList();
  }

  /// Rebuilds [_orderedItems] preserving the current visual order:
  /// - keeps existing tiles in their dragged positions
  /// - removes tiles that became minimized
  /// - appends newly un-minimized tiles at the end
  void _syncOrderedItems() {
    final newNonMin = widget.items.where((m) => !m.isMinimized).toList();
    final newIds = {for (final m in newNonMin) m.menuItemId};
    final oldIds = {for (final m in _orderedItems) m.menuItemId};
    _orderedItems = [
      for (final m in _orderedItems)
        if (newIds.contains(m.menuItemId))
          newNonMin.firstWhere((n) => n.menuItemId == m.menuItemId),
      for (final m in newNonMin)
        if (!oldIds.contains(m.menuItemId)) m,
    ];
  }

  @override
  void didUpdateWidget(DashboardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingItemId != null) return; // defer to onDragEnd
    _syncOrderedItems();
  }

  // ── Drag helpers ──────────────────────────────────────────────────────────

  void _onDrop(String fromId, String toId) {
    final from = _orderedItems.indexWhere((m) => m.menuItemId == fromId);
    final to = _orderedItems.indexWhere((m) => m.menuItemId == toId);
    if (from == -1 || to == -1 || from == to) return;
    setState(() {
      _orderedItems.insert(to, _orderedItems.removeAt(from));
      _hoverTargetId = null;
    });
    _persistReorder();
  }

  void _persistReorder() {
    final menuConfigBloc = context.read<MenuConfigBloc?>();
    final config = menuConfigBloc?.state.menuConfiguration;
    if (config?.menuConfigurationId == null) return;

    final sequences = <Map<String, dynamic>>[
      for (int i = 0; i < _orderedItems.length; i++)
        if (_orderedItems[i].menuItemId != null)
          {'menuItemId': _orderedItems[i].menuItemId!, 'sequenceNum': (i + 1) * 10},
    ];

    menuConfigBloc!.add(
      MenuItemsReorder(
        menuConfigurationId: config!.menuConfigurationId!,
        optionSequences: sequences,
      ),
    );
  }

  /// Ghost placeholder shown in the source tile's slot while dragging.
  Widget _buildGhost(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 2),
        color: cs.primary.withValues(alpha: 0.05),
      ),
    );
  }

  /// Floating card shown under the user's finger while dragging.
  Widget _buildFeedback(
    BuildContext context,
    MenuItem item,
    String et,
    Widget? chartWidget,
  ) {
    final cc = switch (et) { 'statistic' => 2, 'graphic' => 2, _ => 1 };
    final mc = et == 'graphic' ? 2 : 1;
    const spacing = 16.0;
    final w = cc * _colWidth + (cc - 1) * spacing;
    final h = mc * _colWidth + (mc - 1) * spacing;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.85,
        child: SizedBox(
          width: w,
          height: h,
          child: DashboardCard(
            title: item.title,
            iconName: item.iconName ?? 'dashboard',
            route: item.route,
            tileType: et,
            isMinimized: false,
            stats: getStatsForRoute(item.route, widget.stats),
            chartWidget: chartWidget,
            animationIndex: 0,
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = isAPhone(context);

    // Pre-compute chart widgets from the full item list (includes minimized).
    final Map<String, Widget> chartWidgets = {};
    for (final item in widget.items) {
      if (item.route != null && widget.chartBuilder != null) {
        final w = widget.chartBuilder!(item.route!);
        if (w != null) chartWidgets[item.route!] = w;
      }
    }

    String effectiveType(MenuItem m) {
      if (m.isMinimized) return m.tileType;
      if (m.route != null && chartWidgets.containsKey(m.route)) return 'graphic';
      if (getStatsForRoute(m.route, widget.stats) != null) return 'statistic';
      return m.tileType;
    }

    final minimizedItems = widget.items.where((m) => m.isMinimized).toList();
    final crossAxisCount = isPhone ? 3 : 6;

    int crossCells(MenuItem m) => switch (effectiveType(m)) {
      'statistic' => 2,
      'graphic' => 2,
      _ => 1,
    };

    int mainCells(MenuItem m) => effectiveType(m) == 'graphic' ? 2 : 1;

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Store column width so _buildFeedback can size the floating card.
            _colWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                crossAxisCount;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaggeredGrid.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: _orderedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final et = effectiveType(item);
                    final chartWidget =
                        item.route != null ? chartWidgets[item.route] : null;

                    return StaggeredGridTile.count(
                      crossAxisCellCount: crossCells(item),
                      mainAxisCellCount: mainCells(item),
                      child: DragTarget<String>(
                        onWillAcceptWithDetails: (details) {
                          if (details.data != item.menuItemId) {
                            setState(() => _hoverTargetId = item.menuItemId);
                          }
                          return details.data != item.menuItemId;
                        },
                        onLeave: (_) =>
                            setState(() => _hoverTargetId = null),
                        onAcceptWithDetails: (details) =>
                            _onDrop(details.data, item.menuItemId!),
                        builder: (context, candidateData, _) {
                          final isDropTarget =
                              _hoverTargetId == item.menuItemId &&
                              candidateData.isNotEmpty;

                          Widget card = DashboardCard(
                            key: ValueKey(item.menuItemId),
                            title: item.title,
                            iconName: item.iconName ?? 'dashboard',
                            route: item.route,
                            tileType: et,
                            isMinimized: false,
                            stats: getStatsForRoute(item.route, widget.stats),
                            chartWidget: chartWidget,
                            onToggleMinimize:
                                item.menuItemId != null &&
                                        widget.onToggleMinimize != null
                                    ? () => widget.onToggleMinimize!(
                                        item.menuItemId!)
                                    : null,
                            animationIndex: index,
                          );

                          // Highlight border when a dragged tile hovers over this slot.
                          if (isDropTarget) {
                            card = Stack(
                              children: [
                                card,
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.7),
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return LongPressDraggable<String>(
                            data: item.menuItemId,
                            delay: const Duration(milliseconds: 400),
                            onDragStarted: () => setState(
                                () => _draggingItemId = item.menuItemId),
                            onDragEnd: (_) => setState(() {
                              _draggingItemId = null;
                              _hoverTargetId = null;
                              _syncOrderedItems();
                            }),
                            onDraggableCanceled: (v, o) => setState(() {
                              _draggingItemId = null;
                              _hoverTargetId = null;
                            }),
                            feedback: _buildFeedback(
                                context, item, et, chartWidget),
                            childWhenDragging:
                                _buildGhost(colorScheme),
                            child: card,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
                if (minimizedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, innerConstraints) {
                    final miniSize =
                        (innerConstraints.maxWidth -
                                (crossAxisCount - 1) * 16) /
                            crossAxisCount /
                            2;
                    return Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: minimizedItems.asMap().entries.map((entry) {
                        final index =
                            _orderedItems.length + entry.key;
                        final item = entry.value;
                        return SizedBox(
                          width: miniSize,
                          height: miniSize,
                          child: DashboardCard(
                            key: ValueKey('min_${item.menuItemId}'),
                            title: item.title,
                            iconName: item.iconName ?? 'dashboard',
                            route: item.route,
                            tileType: item.tileType,
                            isMinimized: true,
                            stats:
                                getStatsForRoute(item.route, widget.stats),
                            chartWidget: null,
                            onToggleMinimize:
                                item.menuItemId != null &&
                                        widget.onToggleMinimize != null
                                    ? () => widget.onToggleMinimize!(
                                        item.menuItemId!)
                                    : null,
                            animationIndex: index,
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Maps menu option routes to their corresponding statistics from the Stats model.
///
/// Returns null if no matching stats are found for the route.
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
    // Accounting sub-routes
    case '/accounting/sales':
      return 'Open: ${stats.salesInvoicesNotPaidCount}';
    case '/accounting/purchase':
      return 'Open: ${stats.purchInvoicesNotPaidCount}';
    default:
      return null;
  }
}
