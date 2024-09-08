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

class SearchAssetList extends StatefulWidget {
  const SearchAssetList({super.key});

  @override
  SearchAssetState createState() => SearchAssetState();
}

class SearchAssetState extends State<SearchAssetList> {
  late DataFetchBloc _assetBloc;
  List<Asset> locations = [];

  @override
  void initState() {
    super.initState();
    _assetBloc = context.read<DataFetchBloc<Assets>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getAsset(limit: 0)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<Assets>, DataFetchState>(
        listener: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        return Center(
            child: Text('failed to fetch search items: ${state.message}'));
      }
      if (state.status == DataFetchStatus.success) {
        locations = (state.data as Assets).assets;
      }
      return Stack(
        children: [
          AssetScaffold(
              finDocBloc: _assetBloc, widget: widget, locations: locations),
          if (state.status == DataFetchStatus.loading) const LoadingIndicator(),
        ],
      );
    });
  }
}

class AssetScaffold extends StatelessWidget {
  const AssetScaffold({
    super.key,
    required DataFetchBloc finDocBloc,
    required this.widget,
    required this.locations,
  }) : _assetBloc = finDocBloc;

  final DataFetchBloc _assetBloc;
  final SearchAssetList widget;
  final List<Asset> locations;

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key: const Key('SearchDialog'),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: popUp(
                context: context,
                title: 'Asset Search ',
                height: 500,
                width: 350,
                child: Column(children: [
                  TextFormField(
                      key: const Key('searchField'),
                      textInputAction: TextInputAction.search,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: "Search input"),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a search value?';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) => _assetBloc.add(GetDataEvent(
                          () => context
                              .read<RestClient>()
                              .getAsset(limit: 5, searchString: value)))),
                  const SizedBox(height: 20),
                  const Text('Search results'),
                  Expanded(
                      child: ListView.builder(
                          key: const Key('listView'),
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: locations.length + 2,
                          controller: scrollController,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return Visibility(
                                  visible: locations.isEmpty,
                                  child: const Center(
                                      heightFactor: 20,
                                      child: Text('No search items found (yet)',
                                          key: Key('empty'),
                                          textAlign: TextAlign.center)));
                            }
                            index--;
                            return index >= locations.length
                                ? const Text('')
                                : Dismissible(
                                    key: const Key('searchItem'),
                                    direction: DismissDirection.startToEnd,
                                    child: ListTile(
                                      title: Text(
                                          "ID: ${locations[index].pseudoId}\n"
                                          "Name: ${locations[index].assetName}",
                                          key: Key("searchResult$index")),
                                      onTap: () => Navigator.of(context)
                                          .pop(locations[index]),
                                    ));
                          }))
                ]))));
  }
}
