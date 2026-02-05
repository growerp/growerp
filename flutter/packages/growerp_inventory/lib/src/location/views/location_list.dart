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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_inventory/l10n/generated/inventory_localizations.dart';

import '../location.dart';
import 'location_list_styled_data.dart';

class LocationList extends StatefulWidget {
  const LocationList({super.key});

  @override
  LocationListState createState() => LocationListState();
}

class LocationListState extends State<LocationList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late LocationBloc _locationBloc;
  List<Location> locations = const <Location>[];
  late int limit;
  late double bottom;
  double? right;
  late InventoryLocalizations _localizations;
  String searchString = '';
  bool _isLoading = true;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _locationBloc = context.read<LocationBloc>()
      ..add(const LocationFetch(refresh: true));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = InventoryLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    limit = (MediaQuery.of(context).size.height / 100).round();

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = locations.map((location) {
        final index = locations.indexOf(location);
        return getLocationListRow(
          context: context,
          location: location,
          index: index,
          bloc: _locationBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getLocationListColumns(context),
        rows: rows,
        isLoading: _isLoading && locations.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('locationItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _locationBloc,
                  child: LocationDialog(locations[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state.status == LocationStatus.failure) {
          HelperFunctions.showMessage(
            context,
            _localizations.failedToFetchLocations(state.message ?? ''),
            Colors.red,
          );
        }
        if (state.status == LocationStatus.success && state.message != null) {
          HelperFunctions.showMessage(context, state.message!, Colors.green);
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == LocationStatus.loading;

        if (state.status == LocationStatus.failure) {
          return FatalErrorForm(
            message: _localizations.failedToFetchLocations(state.message ?? ''),
          );
        }

        locations = state.locations;
        if (locations.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search locations...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _locationBloc.add(
                  LocationFetch(refresh: true, searchString: value),
                );
              },
            ),
            // Main content area with StyledDataTable
            Expanded(
              child: Stack(
                children: [
                  tableView(),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          right = right! - details.delta.dx;
                          bottom -= details.delta.dy;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            key: const Key("addNew"),
                            heroTag: "locationNew",
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _locationBloc,
                                    child: LocationDialog(Location()),
                                  );
                                },
                              );
                            },
                            tooltip: _localizations.addNew,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom) {
      _locationBloc.add(
        LocationFetch(limit: limit, searchString: searchString),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
