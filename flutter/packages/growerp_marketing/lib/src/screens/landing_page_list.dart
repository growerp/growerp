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

import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import 'generate_landing_page_dialog.dart';
import 'landing_page_detail_screen.dart';
import 'landing_page_list_styled_data.dart';

/// List screen for Landing Pages
class LandingPageList extends StatefulWidget {
  const LandingPageList({super.key});

  @override
  LandingPageListState createState() => LandingPageListState();
}

class LandingPageListState extends State<LandingPageList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
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
        onRowTap: (index) {
          showDialog(
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
        },
      );
    }

    return BlocConsumer<LandingPageBloc, LandingPageState>(
      listener: (context, state) {
        if (state.status == LandingPageStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == LandingPageStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(context, state.message!, Colors.green);
          }
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
              searchHint: 'Search landing pages...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _landingPageBloc.add(LandingPageLoad(searchString: value));
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
