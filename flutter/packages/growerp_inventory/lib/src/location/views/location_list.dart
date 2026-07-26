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
  final _searchFocusNode = FocusNode();
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocusNode.requestFocus(),
    );
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
        onRowTap: (index) async {
          await showDialog(
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
          _searchFocusNode.requestFocus();
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _searchFocusNode.requestFocus(),
          );
        }
        if (state.status == LocationStatus.success && state.message != null) {
          HelperFunctions.showMessage(context, state.message!, Colors.green);
        }
        if (state.status == LocationStatus.success) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _searchFocusNode.requestFocus(),
          );
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
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                searchString = value;
                _locationBloc.add(LocationSearchChanged(searchString: value));
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
                              _searchFocusNode.requestFocus();
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
    _searchFocusNode.dispose();
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
