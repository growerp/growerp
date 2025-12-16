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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';
import 'outreach_message_detail_screen.dart';
import 'outreach_message_list_table_def.dart';

// Table padding and background decoration
const outreachMessagePadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getOutreachMessageBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

class OutreachMessageList extends StatefulWidget {
  const OutreachMessageList({super.key});

  @override
  OutreachMessageListState createState() => OutreachMessageListState();
}

class OutreachMessageListState extends State<OutreachMessageList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late OutreachMessageBloc _messageBloc;
  List<OutreachMessage> messages = const <OutreachMessage>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (messages.isEmpty) {
            return const Center(
              child: Text(
                'No messages found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<OutreachMessage>(
            getOutreachMessageListTableData,
            bloc: _messageBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: messages,
          );

          return TableView.builder(
            diagonalDragBehavior: DiagonalDragBehavior.free,
            verticalDetails: ScrollableDetails.vertical(
              controller: _scrollController,
            ),
            horizontalDetails: ScrollableDetails.horizontal(
              controller: _horizontalController,
            ),
            cellBuilder: (context, vicinity) =>
                tableViewCells[vicinity.row][vicinity.column],
            columnBuilder: (index) => index >= tableViewCells[0].length
                ? null
                : TableSpan(
                    padding: outreachMessagePadding,
                    backgroundDecoration: getOutreachMessageBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: outreachMessagePadding,
                    backgroundDecoration: getOutreachMessageBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(rowHeight!),
                    recognizerFactories: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () => showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return index > messages.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: Key(
                                            'message_${messages[index - 1].messageId}'),
                                        direction: DismissDirection.startToEnd,
                                        child: BlocProvider.value(
                                          value: _messageBloc,
                                          child: OutreachMessageDetailScreen(
                                            message: messages[index - 1],
                                          ),
                                        ),
                                      );
                              },
                            ),
                      ),
                    },
                  ),
            pinnedRowCount: 1,
          );
        }

        blocListener(context, state) {
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
        }

        blocBuilder(context, state) {
          if (state.status == OutreachMessageStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load outreach messages!",
            );
          } else {
            messages = state.messages;
            if (messages.isNotEmpty && _scrollController.hasClients) {
              Future.delayed(const Duration(milliseconds: 100), () {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(currentScroll);
                    }
                  },
                );
              });
            }
            hasReachedMax = state.hasReachedMax;
            return Stack(
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
                      children: [
                        FloatingActionButton(
                          key: const Key("search"),
                          heroTag: "messageBtn1",
                          onPressed: () async {
                            // find message to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _messageBloc,
                                  child: const SearchOutreachMessageList(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _messageBloc,
                                          child: OutreachMessageDetailScreen(
                                            message: value,
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                          child: const Icon(Icons.search),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          key: const Key("addNewMessage"),
                          heroTag: "messageBtn2",
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
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }

        return BlocConsumer<OutreachMessageBloc, OutreachMessageState>(
          listener: blocListener,
          builder: blocBuilder,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the controller is attached before accessing position properties
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    currentScroll = _scrollController.position.pixels;
    if (!hasReachedMax &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _scrollThreshold) {
      _messageBloc.add(
        OutreachMessageLoad(
          start: messages.length,
        ),
      );
    }
  }
}

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
                border: const OutlineInputBorder(),
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
