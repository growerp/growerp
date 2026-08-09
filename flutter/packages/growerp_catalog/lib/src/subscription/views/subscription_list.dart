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
  final _searchFocusNode = FocusNode();
  late SubscriptionBloc _subscriptionBloc;
  late List<Subscription> subscriptions;
  late String applicationId;
  late String entityName;
  late bool started;
  late int limit;
  String _searchQuery = '';
  late double bottom;
  double? right;

  @override
  void initState() {
    super.initState();
    started = false;
    _scrollController.addListener(_onScroll);
    _subscriptionBloc = context.read<SubscriptionBloc>()
      ..add(const SubscriptionFetch(refresh: true));
    applicationId = context.read<String>();
    entityName = 'Subscription';
    bottom = 50;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocusNode.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var catalogLocalizations = CatalogLocalizations.of(context)!;
    var coreLocalizations = CoreLocalizations.of(context)!;
    limit = (MediaQuery.of(context).size.height / 100).round();
    bool isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.status == SubscriptionStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _searchFocusNode.requestFocus(),
          );
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _searchFocusNode.requestFocus(),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SubscriptionStatus.failure) {
          return Center(
            child: Text(
              catalogLocalizations.fetchSubscriptionError(state.message ?? ''),
            ),
          );
        }

        subscriptions = state.subscriptions;
        final isLoading = state.status == SubscriptionStatus.loading;

        return Column(
          children: [
            ListFilterBar(
              searchHint: catalogLocalizations.subscriptionSearch,
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _subscriptionBloc.add(
                  SubscriptionSearchChanged(searchString: value),
                );
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  isLoading && subscriptions.isEmpty
                      ? const Center(child: LoadingIndicator())
                      : StyledDataTable(
                          scrollController: _scrollController,
                          columns: getSubscriptionColumns(context, isPhone),
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
                          isLoading: isLoading,
                          onRowTap: (index) async {
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _subscriptionBloc,
                                  child: SubscriptionDialog(
                                    subscriptions[index],
                                  ),
                                );
                              },
                            );
                            _searchFocusNode.requestFocus();
                          },
                        ),
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
                      child: FloatingActionButton(
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
                          _searchFocusNode.requestFocus();
                        },
                        tooltip: coreLocalizations.addNew,
                        child: const Icon(Icons.add),
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
