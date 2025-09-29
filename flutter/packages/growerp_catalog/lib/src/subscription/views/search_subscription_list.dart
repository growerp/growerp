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

import '../../../growerp_catalog.dart';

class SearchSubscriptionList extends StatefulWidget {
  const SearchSubscriptionList({super.key});

  @override
  SearchSubscriptionState createState() => SearchSubscriptionState();
}

class SearchSubscriptionState extends State<SearchSubscriptionList> {
  late SubscriptionBloc _subscriptionBloc;
  List<Subscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = context.read<SubscriptionBloc>();
  }

  @override
  Widget build(BuildContext context) {
    var catalogLocalizations = CatalogLocalizations.of(context)!;
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.status == SubscriptionStatus.failure) {
          HelperFunctions.showMessage(
            context,
            catalogLocalizations.error(state.message ?? ''),
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        if (state.status == SubscriptionStatus.failure) {
          return Center(
            child: Text(
              catalogLocalizations.fetchSearchError(state.message ?? ''),
            ),
          );
        }
        if (state.status == SubscriptionStatus.success) {
          subscriptions = state.searchResults ?? [];
        }
        return Stack(
          children: [
            SubscriptionSearchDialog(
              subscriptionBloc: _subscriptionBloc,
              widget: widget,
              subscriptions: subscriptions,
            ),
            if (state.status == SubscriptionStatus.loading)
              const LoadingIndicator(),
          ],
        );
      },
    );
  }
}

class SubscriptionSearchDialog extends StatelessWidget {
  const SubscriptionSearchDialog({
    super.key,
    required this.subscriptionBloc,
    required this.widget,
    required this.subscriptions,
  });

  final SubscriptionBloc subscriptionBloc;
  final SearchSubscriptionList widget;
  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context) {
    var catalogLocalizations = CatalogLocalizations.of(context)!;
    final ScrollController scrollController = ScrollController();
    return Dialog(
      key: const Key('SearchDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: catalogLocalizations.subscriptionSearch,
        height: 500,
        width: 350,
        child: Column(
          children: [
            TextFormField(
              key: const Key('searchField'),
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: catalogLocalizations.searchInput,
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return catalogLocalizations.enterSearch;
                }
                return null;
              },
              onFieldSubmitted: (value) => subscriptionBloc.add(
                SubscriptionFetch(limit: 5, searchString: value),
              ),
            ),
            const SizedBox(height: 20),
            Text(catalogLocalizations.searchResults),
            Expanded(
              child: ListView.builder(
                key: const Key('listView'),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: subscriptions.length + 2,
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Visibility(
                      visible: subscriptions.isEmpty,
                      child: Center(
                        heightFactor: 20,
                        child: Text(
                          catalogLocalizations.noSearchItems,
                          key: const Key('empty'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  index--;
                  return index >= subscriptions.length
                      ? const Text('')
                      : Dismissible(
                          key: const Key('searchItem'),
                          direction: DismissDirection.startToEnd,
                          child: ListTile(
                            title: Text(
                              "${catalogLocalizations.id(subscriptions[index].pseudoId ?? '')}\n"
                              "${catalogLocalizations.subscriber(subscriptions[index].subscriber?.name ?? '')}",
                              key: Key("searchResult$index"),
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(subscriptions[index]),
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
