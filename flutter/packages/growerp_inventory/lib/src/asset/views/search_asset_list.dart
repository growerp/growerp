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
import 'package:growerp_inventory/l10n/generated/inventory_localizations.dart';

class SearchAssetList extends StatefulWidget {
  const SearchAssetList({super.key});

  @override
  SearchAssetState createState() => SearchAssetState();
}

class SearchAssetState extends State<SearchAssetList> {
  late DataFetchBloc<Assets> _assetBloc;
  List<Asset> assets = [];
  late InventoryLocalizations localizations;

  @override
  void initState() {
    super.initState();
    _assetBloc = context.read<DataFetchBloc<Assets>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getAsset(limit: 0)));
  }

  @override
  Widget build(BuildContext context) {
    localizations = InventoryLocalizations.of(context)!;
    return BlocConsumer<DataFetchBloc<Assets>, DataFetchState<Assets>>(
      listener: (context, state) {
        if (state.status == DataFetchStatus.failure) {
          HelperFunctions.showMessage(
            context,
            localizations.error(state.message ?? ''),
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        if (state.status == DataFetchStatus.failure) {
          return Center(
            child: Text(
              localizations.failedToFetchSearchItems(state.message ?? ''),
            ),
          );
        }
        if (state.status == DataFetchStatus.success) {
          assets = (state.data as Assets).assets;
        }
        return Stack(
          children: [
            AssetSearchDialog(
              assetBloc: _assetBloc,
              widget: widget,
              assets: assets,
            ),
            if (state.status == DataFetchStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}

class AssetSearchDialog extends StatelessWidget {
  const AssetSearchDialog({
    super.key,
    required DataFetchBloc<Assets> assetBloc,
    required this.widget,
    required this.assets,
  }) : _assetBloc = assetBloc;

  final DataFetchBloc<Assets> _assetBloc;
  final SearchAssetList widget;
  final List<Asset> assets;

  @override
  Widget build(BuildContext context) {
    final InventoryLocalizations localizations = InventoryLocalizations.of(
      context,
    )!;
    final ScrollController scrollController = ScrollController();
    return Dialog(
      key: const Key('SearchDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: localizations.assetSearch,
        height: 500,
        width: 350,
        child: Column(
          children: [
            TextFormField(
              key: const Key('searchField'),
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(labelText: localizations.searchInput),
              validator: (value) {
                if (value!.isEmpty) {
                  return localizations.enterSearchValue;
                }
                return null;
              },
              onFieldSubmitted: (value) => _assetBloc.add(
                GetDataEvent(
                  () => context.read<RestClient>().getAsset(
                    limit: 5,
                    searchString: value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(localizations.searchResults),
            Expanded(
              child: ListView.builder(
                key: const Key('listView'),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: assets.length + 2,
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Visibility(
                      visible: assets.isEmpty,
                      child: Center(
                        heightFactor: 20,
                        child: Text(
                          localizations.noSearchItemsFound,
                          key: const Key('empty'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  index--;
                  return index >= assets.length
                      ? const Text('')
                      : Dismissible(
                          key: const Key('searchItem'),
                          direction: DismissDirection.startToEnd,
                          child: ListTile(
                            title: Text(
                              "${localizations.id}${assets[index].pseudoId}\n"
                              "${localizations.name}${assets[index].assetName}",
                              key: Key("searchResult$index"),
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(assets[index]),
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
