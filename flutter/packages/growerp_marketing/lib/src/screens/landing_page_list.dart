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

import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import 'generate_landing_page_dialog.dart';
import 'landing_page_detail_screen.dart';
import 'landing_page_list_styled_data.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// List screen for Landing Pages
class LandingPageList extends StatefulWidget {
  const LandingPageList({super.key});

  @override
  LandingPageListState createState() => LandingPageListState();
}

class LandingPageListState extends State<LandingPageList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late LandingPageBloc _landingPageBloc;
  late AuthBloc _authBloc;
  List<LandingPage> landingPages = const <LandingPage>[];
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
    _landingPageBloc = context.read<LandingPageBloc>()
      ..add(const LandingPageLoad(start: 0));
    _authBloc = context.read<AuthBloc>();
    bottom = 50;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = landingPages.map((page) {
        final index = landingPages.indexOf(page);
        return getLandingPageListRow(
          context: context,
          page: page,
          index: index,
          bloc: _landingPageBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getLandingPageListColumns(context),
        rows: rows,
        isLoading: _isLoading && landingPages.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) async {
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('landingPageDetailScreen'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _landingPageBloc,
                  child: LandingPageDetailScreen(
                    landingPage: landingPages[index],
                  ),
                ),
              );
            },
          );
          if (mounted) _searchFocusNode.requestFocus();
        },
      );
    }

    return BlocConsumer<LandingPageBloc, LandingPageState>(
      listener: (context, state) {
        if (state.status == LandingPageStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          _searchFocusNode.requestFocus();
        }
        if (state.status == LandingPageStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(context, state.message!, Colors.green);
          }
          _searchFocusNode.requestFocus();
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == LandingPageStatus.loading;

        if (state.status == LandingPageStatus.failure && landingPages.isEmpty) {
          return const FatalErrorForm(message: 'Could not load landing pages!');
        }

        landingPages = state.landingPages;
        if (landingPages.isNotEmpty && _scrollController.hasClients) {
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
              searchHint: MarketingLocalizations.of(
                context,
              )!.searchHintLandingPages,
              searchController: _searchController,
              focusNode: _searchFocusNode,
              onSearchChanged: (value) {
                searchString = value;
                _landingPageBloc.add(LandingPageSearchRequested(query: value));
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
                            key: const Key('addNewLandingPage'),
                            heroTag: 'landingPageBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _landingPageBloc,
                                    child: const LandingPageDetailScreen(
                                      landingPage: LandingPage(
                                        title: '',
                                        status: 'DRAFT',
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (mounted) _searchFocusNode.requestFocus();
                            },
                            tooltip: 'Add new landing page',
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            key: const Key('generateAILandingPage'),
                            heroTag: 'landingPageBtn2',
                            onPressed: () async {
                              // Get ownerPartyId from the stored auth bloc
                              final authState = _authBloc.state;

                              if (authState.status !=
                                  AuthStatus.authenticated) {
                                if (mounted) {
                                  HelperFunctions.showMessage(
                                    context,
                                    'Error: Authentication required. Please log in.',
                                    Colors.red,
                                  );
                                }
                                return;
                              }

                              if (!mounted) return;
                              await showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return GenerateLandingPageDialog(
                                    onSuccess: (landingPage) {
                                      // Refresh the list
                                      _landingPageBloc.add(
                                        const LandingPageLoad(),
                                      );

                                      // Show success message
                                      if (mounted) {
                                        HelperFunctions.showMessage(
                                          context,
                                          'Landing page "${landingPage.title}" created successfully!',
                                          Colors.green,
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                              if (mounted) _searchFocusNode.requestFocus();
                            },
                            tooltip: 'Generate Landing Page with AI',
                            child: const Icon(Icons.auto_awesome),
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
      _landingPageBloc.add(
        LandingPageLoad(start: landingPages.length, searchString: searchString),
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
