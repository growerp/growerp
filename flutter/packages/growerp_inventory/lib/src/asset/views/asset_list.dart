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

import '../asset.dart';
import 'asset_list_styled_data.dart';

class AssetList extends StatefulWidget {
  const AssetList({super.key});
  @override
  AssetListState createState() => AssetListState();
}

class AssetListState extends State<AssetList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late AssetBloc _assetBloc;
  List<Asset> assets = const <Asset>[];
  late String classificationId;
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
    classificationId = context.read<String>();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'Asset';
    _scrollController.addListener(_onScroll);
    _assetBloc = context.read<AssetBloc>()
      ..add(const AssetFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = InventoryLocalizations.of(context)!;
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
          classificationId: classificationId,
        );
      }).toList();

      return StyledDataTable(
        columns: getAssetListColumns(
          context,
          classificationId: classificationId,
        ),
        rows: rows,
        isLoading: _isLoading && assets.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('assetItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _assetBloc,
                  child: AssetDialog(assets[index]),
                ),
              );
            },
          );
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
        }
        if (state.status == AssetStatus.success) {
          if (state.message != null && state.message!.isNotEmpty) {
            HelperFunctions.showMessage(context, state.message!, Colors.green);
          }
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
              searchHint: 'Search ${entityName.toLowerCase()}s...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _assetBloc.add(AssetFetch(refresh: true, searchString: value));
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
      _assetBloc.add(AssetFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
