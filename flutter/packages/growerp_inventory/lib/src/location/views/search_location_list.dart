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

class SearchLocationList extends StatefulWidget {
  const SearchLocationList({super.key});

  @override
  SearchLocationState createState() => SearchLocationState();
}

class SearchLocationState extends State<SearchLocationList> {
  late DataFetchBloc<Locations> _locationBloc;
  List<Location> locations = [];
  late InventoryLocalizations localizations;

  @override
  void initState() {
    super.initState();
    _locationBloc = context.read<DataFetchBloc<Locations>>()
      ..add(
        GetDataEvent(() => context.read<RestClient>().getLocation(limit: 0)),
      );
  }

  @override
  Widget build(BuildContext context) {
    localizations = InventoryLocalizations.of(context)!;
    return BlocConsumer<DataFetchBloc<Locations>, DataFetchState<Locations>>(
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
          locations = (state.data as Locations).locations;
        }
        return Stack(
          children: [
            LocationSearchDialog(
              finDocBloc: _locationBloc,
              widget: widget,
              locations: locations,
            ),
            if (state.status == DataFetchStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}

class LocationSearchDialog extends StatelessWidget {
  const LocationSearchDialog({
    super.key,
    required DataFetchBloc<Locations> finDocBloc,
    required this.widget,
    required this.locations,
  }) : _locationBloc = finDocBloc;

  final DataFetchBloc<Locations> _locationBloc;
  final SearchLocationList widget;
  final List<Location> locations;

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
        title: localizations.locationSearch,
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
              onFieldSubmitted: (value) => _locationBloc.add(
                GetDataEvent(
                  () => context.read<RestClient>().getLocation(
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
                itemCount: locations.length + 2,
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Visibility(
                      visible: locations.isEmpty,
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
                  return index >= locations.length
                      ? const Text('')
                      : Dismissible(
                          key: const Key('searchItem'),
                          direction: DismissDirection.startToEnd,
                          child: ListTile(
                            title: Text(
                              "${localizations.id}"
                              "${locations[index].pseudoId}\n"
                              "${localizations.name}"
                              "${locations[index].locationName}",
                              key: Key("searchResult$index"),
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(locations[index]),
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
