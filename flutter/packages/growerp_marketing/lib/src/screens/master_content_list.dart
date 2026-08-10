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

import '../bloc/master_content_bloc.dart';
import '../bloc/master_content_event.dart';
import '../bloc/master_content_state.dart';
import 'master_content_detail_screen.dart';
import 'master_content_list_styled_data.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// List screen for platform-neutral Master Content
class MasterContentList extends StatefulWidget {
  const MasterContentList({super.key});

  @override
  MasterContentListState createState() => MasterContentListState();
}

class MasterContentListState extends State<MasterContentList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late MasterContentBloc _masterContentBloc;
  List<MasterContent> masterContents = const <MasterContent>[];
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
    _masterContentBloc = context.read<MasterContentBloc>()
      ..add(const MasterContentFetch(refresh: true));
    bottom = 50;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MarketingLocalizations.of(context)!;
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      final rows = masterContents.map((content) {
        final index = masterContents.indexOf(content);
        return getMasterContentListRow(
          context: context,
          content: content,
          index: index,
          bloc: _masterContentBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getMasterContentListColumns(context),
        rows: rows,
        isLoading: _isLoading && masterContents.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) async {
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('masterContentDetailScreen'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _masterContentBloc,
                  child: MasterContentDetailScreen(
                      masterContent: masterContents[index]),
                ),
              );
            },
          );
          if (mounted) _searchFocusNode.requestFocus();
        },
      );
    }

    return BlocConsumer<MasterContentBloc, MasterContentState>(
      listener: (context, state) {
        if (state.status == MasterContentStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          _searchFocusNode.requestFocus();
        }
        if (state.status == MasterContentStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(context, state.message!, Colors.green);
          }
          _searchFocusNode.requestFocus();
        }
      },
      builder: (context, state) {
        _isLoading = state.status == MasterContentStatus.loading;

        if (state.status == MasterContentStatus.failure &&
            masterContents.isEmpty) {
          return const FatalErrorForm(
              message: 'Could not load master content!');
        }

        masterContents = state.masterContents;
        if (masterContents.isNotEmpty && _scrollController.hasClients) {
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
            ListFilterBar(
              searchHint: localizations.searchHintMasterContent,
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                searchString = value;
                _masterContentBloc.add(
                  MasterContentSearchRequested(searchString: value),
                );
              },
            ),
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
                            key: const Key('addNewMasterContent'),
                            heroTag: 'masterContentBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _masterContentBloc,
                                    child: const MasterContentDetailScreen(
                                      masterContent: null,
                                    ),
                                  );
                                },
                              );
                              if (mounted) _searchFocusNode.requestFocus();
                            },
                            tooltip: 'Add new master content',
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
    if (_isBottom && !hasReachedMax) {
      _masterContentBloc.add(
        MasterContentFetch(
            start: masterContents.length, searchString: searchString),
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
