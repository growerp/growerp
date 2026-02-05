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
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'subscription_list_styled_data.dart';

class SubscriptionList extends StatefulWidget {
  const SubscriptionList({super.key});
  @override
  SubscriptionListState createState() => SubscriptionListState();
}

class SubscriptionListState extends State<SubscriptionList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late SubscriptionBloc _subscriptionBloc;
  late List<Subscription> subscriptions;
  late String classificationId;
  late String entityName;
  late bool started;
  late int limit;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _subscriptionBloc = context.read<SubscriptionBloc>()
      ..add(const SubscriptionFetch(refresh: true));
    classificationId = context.read<String>();
    entityName = 'Subscription';
  }

  @override
  Widget build(BuildContext context) {
    var catalogLocalizations = CatalogLocalizations.of(context)!;
    var coreLocalizations = CoreLocalizations.of(context)!;
    limit = (MediaQuery.of(context).size.height / 100).round();
    bool isPhone = isAPhone(context);

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.status == SubscriptionStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == SubscriptionStatus.success) {
          started = true;
          final translatedMessage = state.message != null
              ? translateSubscriptionBlocMessage(
                  state.message!,
                  catalogLocalizations,
                )
              : '';
          if (translatedMessage.isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              translatedMessage,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case SubscriptionStatus.failure:
            return Center(
              child: Text(
                catalogLocalizations.fetchSubscriptionError(
                  state.message ?? '',
                ),
              ),
            );
          case SubscriptionStatus.success:
            subscriptions = state.subscriptions;
            return Scaffold(
              floatingActionButton: FloatingActionButton(
                heroTag: 'subscriptionNew',
                key: const Key('addNew'),
                onPressed: () async {
                  await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return BlocProvider.value(
                        value: _subscriptionBloc,
                        child: SubscriptionDialog(Subscription()),
                      );
                    },
                  );
                },
                tooltip: coreLocalizations.addNew,
                child: const Icon(Icons.add),
              ),
              body: Column(
                children: [
                  ListFilterBar(
                    searchHint: catalogLocalizations.subscriptionSearch,
                    searchController: _searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      if (value.length > 2) {
                        _subscriptionBloc.add(
                          SubscriptionFetch(refresh: true, searchString: value),
                        );
                      } else if (value.isEmpty) {
                        _subscriptionBloc.add(
                          const SubscriptionFetch(refresh: true),
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: StyledDataTable(
                      scrollController: _scrollController,
                      columns: getSubscriptionColumns(isPhone),
                      rows: subscriptions.isEmpty
                          ? []
                          : subscriptions
                                .asMap()
                                .entries
                                .map(
                                  (entry) => buildSubscriptionRow(
                                    context,
                                    entry.value,
                                    entry.key,
                                    isPhone,
                                  ),
                                )
                                .toList(),
                      isLoading:
                          state.status == SubscriptionStatus.loading &&
                          subscriptions.isEmpty,
                      onRowTap: (index) {
                        showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider.value(
                              value: _subscriptionBloc,
                              child: SubscriptionDialog(subscriptions[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          default:
            return const Center(child: LoadingIndicator());
        }
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
    if (_isBottom) {
      _subscriptionBloc.add(
        SubscriptionFetch(limit: limit, searchString: _searchQuery),
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
