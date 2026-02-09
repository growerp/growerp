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

import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';
import 'outreach_message_detail_screen.dart';
import 'outreach_message_list_styled_data.dart';

/// List screen for Outreach Messages
class OutreachMessageList extends StatefulWidget {
  const OutreachMessageList({super.key});

  @override
  OutreachMessageListState createState() => OutreachMessageListState();
}

class OutreachMessageListState extends State<OutreachMessageList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late OutreachMessageBloc _messageBloc;
  List<OutreachMessage> messages = const <OutreachMessage>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;
  String searchString = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageBloc = context.read<OutreachMessageBloc>()
      ..add(const OutreachMessageLoad(start: 0));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = messages.map((message) {
        final index = messages.indexOf(message);
        return getOutreachMessageListRow(
          context: context,
          message: message,
          index: index,
          bloc: _messageBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getOutreachMessageListColumns(context),
        rows: rows,
        isLoading: _isLoading && messages.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: Key('messageDetailScreen${messages[index].messageId}'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _messageBloc,
                  child: OutreachMessageDetailScreen(message: messages[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<OutreachMessageBloc, OutreachMessageState>(
      listener: (context, state) {
        if (state.status == OutreachMessageStatus.failure) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.red,
          );
        }
        if (state.status == OutreachMessageStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == OutreachMessageStatus.loading;

        if (state.status == OutreachMessageStatus.failure && messages.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load outreach messages!',
          );
        }

        messages = state.messages;
        if (messages.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }
        hasReachedMax = state.hasReachedMax;

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search messages...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _messageBloc.add(
                  OutreachMessageSearchRequested(query: value),
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
                            key: const Key('addNewMessage'),
                            heroTag: 'messageBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _messageBloc,
                                    child: const OutreachMessageDetailScreen(
                                      message: OutreachMessage(
                                        platform: 'EMAIL',
                                        messageContent: '',
                                        status: 'PENDING',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            tooltip: 'Add new message',
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
    if (_isBottom && !hasReachedMax) {
      _messageBloc.add(
        OutreachMessageLoad(start: messages.length),
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

/// Search dialog for outreach messages
class SearchOutreachMessageList extends StatefulWidget {
  const SearchOutreachMessageList({super.key});

  @override
  SearchOutreachMessageListState createState() =>
      SearchOutreachMessageListState();
}

class SearchOutreachMessageListState extends State<SearchOutreachMessageList> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late OutreachMessageBloc _messageBloc;

  @override
  void initState() {
    super.initState();
    _messageBloc = context.read<OutreachMessageBloc>();
  }

  @override
  void dispose() {
    searchBoxController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('SearchMessageDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Outreach Messages',
        child: Column(
          children: [
            TextFormField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search messages',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchBoxController.clear();
                    _messageBloc.add(
                      const OutreachMessageSearchRequested(query: ''),
                    );
                  },
                ),
              ),
              onFieldSubmitted: (value) {
                _messageBloc.add(
                  OutreachMessageSearchRequested(query: value),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<OutreachMessageBloc, OutreachMessageState>(
                builder: (context, state) {
                  final searchStatus = state.searchStatus;
                  if (searchStatus == OutreachMessageStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (searchStatus == OutreachMessageStatus.failure) {
                    return Center(
                      child: Text(
                        state.searchError ?? 'Search failed, please try again.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (state.searchResults.isEmpty) {
                    final message =
                        searchStatus == OutreachMessageStatus.initial
                            ? 'Enter a search term to begin.'
                            : 'No messages matched your search.';
                    return Center(
                      child: Text(message),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final message = state.searchResults[index];
                      return ListTile(
                        key: Key('messageSearchItem$index'),
                        title: Text(
                          message.recipientName ??
                              message.recipientEmail ??
                              'Unknown',
                        ),
                        subtitle: Text(
                          '${message.platform} - ${message.status}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(message),
                      );
                    },
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
