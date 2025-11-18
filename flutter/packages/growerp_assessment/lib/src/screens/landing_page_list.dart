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

import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import 'generate_landing_page_dialog.dart';
import 'landing_page_detail_screen.dart';
import 'landing_page_list_table_def.dart';

// Table padding and background decoration
const landingPagePadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getLandingPageBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

class LandingPageList extends StatefulWidget {
  const LandingPageList({super.key});

  @override
  LandingPageListState createState() => LandingPageListState();
}

class LandingPageListState extends State<LandingPageList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late LandingPageBloc _landingPageBloc;
  List<LandingPage> landingPages = const <LandingPage>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;
  late AuthBloc _authBloc;

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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (landingPages.isEmpty) {
            return const Center(
              child: Text(
                'No landing pages found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<LandingPage>(
            getLandingPageListTableData,
            bloc: _landingPageBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: landingPages,
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
                    padding: landingPagePadding,
                    backgroundDecoration: getLandingPageBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: landingPagePadding,
                    backgroundDecoration: getLandingPageBackGround(
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
                                return index > landingPages.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: const Key('xxxxxx'),
                                        direction: DismissDirection.startToEnd,
                                        child: BlocProvider.value(
                                          value: _landingPageBloc,
                                          child: LandingPageDetailScreen(
                                            landingPage:
                                                landingPages[index - 1],
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
          if (state.status == LandingPageStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
          }
          if (state.status == LandingPageStatus.success) {
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
          if (state.status == LandingPageStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load landing pages!",
            );
          } else {
            landingPages = state.landingPages;
            if (landingPages.isNotEmpty && _scrollController.hasClients) {
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
                          heroTag: "landingPageBtn1",
                          onPressed: () async {
                            // find landing page id to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _landingPageBloc,
                                  child: const SearchLandingPageList(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _landingPageBloc,
                                          child: LandingPageDetailScreen(
                                            landingPage: value,
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
                          key: const Key("addNewLandingPage"),
                          heroTag: "landingPageBtn2",
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
                          key: const Key("generateAILandingPage"),
                          heroTag: "landingPageBtn3",
                          onPressed: () async {
                            // Get ownerPartyId from the stored auth bloc
                            final authState = _authBloc.state;

                            if (authState.status != AuthStatus.authenticated) {
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
                                    _landingPageBloc
                                        .add(const LandingPageLoad());

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
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }

        return BlocConsumer<LandingPageBloc, LandingPageState>(
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
      _landingPageBloc.add(
        LandingPageLoad(
          start: landingPages.length,
          search: searchString,
        ),
      );
    }
  }
}

class SearchLandingPageList extends StatefulWidget {
  const SearchLandingPageList({super.key});

  @override
  SearchLandingPageListState createState() => SearchLandingPageListState();
}

class SearchLandingPageListState extends State<SearchLandingPageList> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late LandingPageBloc _landingPageBloc;

  @override
  void initState() {
    super.initState();
    _landingPageBloc = context.read<LandingPageBloc>();
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
      key: const Key('SearchLandingPageDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Landing Pages',
        child: Column(
          children: [
            TextFormField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search landing pages',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => searchBoxController.clear(),
                ),
              ),
              onFieldSubmitted: (value) {
                _landingPageBloc.add(
                  LandingPageLoad(
                    search: value,
                    start: 0,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<LandingPageBloc, LandingPageState>(
                builder: (context, state) {
                  if (state.status == LandingPageStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (state.landingPages.isEmpty) {
                    return const Center(
                      child: Text('No landing pages found'),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.landingPages.length,
                    itemBuilder: (context, index) {
                      final landingPage = state.landingPages[index];
                      return ListTile(
                        key: Key('landingPageSearchItem$index'),
                        title: Text(landingPage.title),
                        subtitle: Text(
                          landingPage.pseudoId ?? 'N/A',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(landingPage),
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
