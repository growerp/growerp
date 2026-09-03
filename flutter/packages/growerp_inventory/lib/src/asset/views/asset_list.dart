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
import 'package:growerp_inventory/growerp_inventory.dart';

import 'asset_list_styled_data.dart';

class AssetList extends StatefulWidget {
  const AssetList({super.key});
  @override
  AssetListState createState() => AssetListState();
}

class AssetListState extends State<AssetList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late AssetBloc _assetBloc;
  List<Asset> assets = const <Asset>[];
  late String applicationId;
  late String entityName;
  late double bottom;
  double? right;
  late InventoryLocalizations _localizations;
  String searchString = '';
  bool _isLoading = true;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    applicationId = context.read<String>();
    entityName = applicationId == 'AppHotel'
        ? 'Room'
        : applicationId == 'AppRental'
            ? 'Equipment'
            : 'Asset';
    _scrollController.addListener(_onScroll);
    _assetBloc = context.read<AssetBloc>()
      ..add(const AssetFetch(refresh: true));
    bottom = 50;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocusNode.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = InventoryLocalizations.of(context)!;
    final noun = applicationId == 'AppHotel'
        ? _localizations.assetNounRoom
        : applicationId == 'AppRental'
            ? _localizations.assetNounEquipment
            : _localizations.assetNounAsset;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = assets.map((asset) {
        final index = assets.indexOf(asset);
        return getAssetListRow(
          context: context,
          asset: asset,
          index: index,
          bloc: _assetBloc,
          applicationId: applicationId,
        );
      }).toList();

      return StyledDataTable(
        columns: getAssetListColumns(
          context,
          applicationId: applicationId,
        ),
        rows: rows,
        isLoading: _isLoading && assets.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) async {
          if (index < 0 || index >= assets.length) return;
          // Capture the asset now: the dialog's builder runs again on every
          // bloc rebuild, and a search behind the open dialog can empty
          // `assets`, so indexing the live list there throws a RangeError.
          final asset = assets[index];
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('assetItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _assetBloc,
                  child: AssetDialog(asset),
                ),
              );
            },
          );
          _searchFocusNode.requestFocus();
        },
      );
    }

    return BlocConsumer<AssetBloc, AssetState>(
      listenWhen: (previous, current) => previous.status == AssetStatus.loading,
      listener: (context, state) {
        if (state.status == AssetStatus.failure) {
          HelperFunctions.showMessage(
            context,
            _localizations.error(state.message ?? ''),
            Colors.red,
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _searchFocusNode.requestFocus(),
          );
        }
        if (state.status == AssetStatus.success) {
          if (state.message != null && state.message!.isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              translateAssetBlocMessage(state.message, _localizations),
              Colors.green,
            );
          }
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _searchFocusNode.requestFocus(),
          );
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == AssetStatus.loading;

        if (state.status == AssetStatus.failure) {
          return FatalErrorForm(
            message: _localizations.failedToFetchAssets(state.message ?? ''),
          );
        }

        assets = state.assets;
        if (assets.isNotEmpty && _scrollController.hasClients) {
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
              searchHint: _localizations.searchHintNoun(noun),
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                searchString = value;
                _assetBloc.add(AssetSearchChanged(searchString: value));
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
                            heroTag: "assetNew",
                            key: const Key("addNew"),
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _assetBloc,
                                    child: AssetDialog(Asset()),
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
      _assetBloc.add(AssetFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    // Nothing to page when the list fits on screen (e.g. a 1-row search result);
    // otherwise scroll-triggered fetches fire endlessly on short lists.
    if (maxScroll <= 0) return false;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
