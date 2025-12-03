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

import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';
import '../bloc/social_post_state.dart';
import 'social_post_detail_screen.dart';
import 'social_post_list_table_def.dart';

// Table padding and background decoration
const socialPostPadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getSocialPostBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

/// List screen for Social Posts
class SocialPostList extends StatefulWidget {
  const SocialPostList({super.key});

  @override
  SocialPostListState createState() => SocialPostListState();
}

class SocialPostListState extends State<SocialPostList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late SocialPostBloc _socialPostBloc;
  List<SocialPost> socialPosts = const <SocialPost>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _socialPostBloc = context.read<SocialPostBloc>()
      ..add(const SocialPostFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (socialPosts.isEmpty) {
            return const Center(
              child: Text(
                'No social posts found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<SocialPost>(
            getSocialPostListTableData,
            bloc: _socialPostBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: socialPosts,
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
                    padding: socialPostPadding,
                    backgroundDecoration: getSocialPostBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: socialPostPadding,
                    backgroundDecoration: getSocialPostBackGround(
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
                                return index > socialPosts.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key:
                                            const Key('socialPostDetailScreen'),
                                        direction: DismissDirection.startToEnd,
                                        child: BlocProvider.value(
                                          value: _socialPostBloc,
                                          child: SocialPostDetailScreen(
                                            socialPost: socialPosts[index - 1],
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
          if (state.status == SocialPostStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
          }
          if (state.status == SocialPostStatus.success) {
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
          if (state.status == SocialPostStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load social posts!",
            );
          } else {
            socialPosts = state.socialPosts;
            if (socialPosts.isNotEmpty && _scrollController.hasClients) {
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
                          heroTag: "socialPostBtn1",
                          onPressed: () async {
                            // find social post id to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _socialPostBloc,
                                  child: const SearchSocialPostDialog(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _socialPostBloc,
                                          child: SocialPostDetailScreen(
                                            socialPost: value,
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
                          key: const Key("addNewSocialPost"),
                          heroTag: "socialPostBtn2",
                          onPressed: () async {
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _socialPostBloc,
                                  child: const SocialPostDetailScreen(
                                      socialPost: null),
                                );
                              },
                            );
                          },
                          tooltip: 'Add new social post',
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

        return BlocConsumer<SocialPostBloc, SocialPostState>(
          listener: blocListener,
          builder: blocBuilder,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
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
      _socialPostBloc.add(
        SocialPostFetch(
          start: socialPosts.length,
        ),
      );
    }
  }
}

/// Search dialog for social posts
class SearchSocialPostDialog extends StatefulWidget {
  const SearchSocialPostDialog({super.key});

  @override
  SearchSocialPostDialogState createState() => SearchSocialPostDialogState();
}

class SearchSocialPostDialogState extends State<SearchSocialPostDialog> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late SocialPostBloc _socialPostBloc;

  @override
  void initState() {
    super.initState();
    _socialPostBloc = context.read<SocialPostBloc>();
  }

  @override
  void dispose() {
    searchBoxController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _socialPostBloc.add(const SocialPostSearchRequested(searchString: ''));
      return;
    }
    _socialPostBloc.add(SocialPostSearchRequested(searchString: query));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('SearchSocialPostDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Social Posts',
        child: Column(
          children: [
            TextField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search by ID, headline, or type',
                hintText: 'Enter ID, headline, or type',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchBoxController.clear();
                    _performSearch('');
                  },
                ),
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<SocialPostBloc, SocialPostState>(
                builder: (context, state) {
                  if (state.searchStatus == SocialPostStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (state.searchStatus == SocialPostStatus.failure) {
                    return Center(
                      child: Text(
                        state.searchError ?? 'Search failed',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (state.searchResults.isEmpty) {
                    final message = searchBoxController.text.isEmpty
                        ? 'Enter a search term to begin.'
                        : 'No social posts matched your search.';
                    return Center(child: Text(message));
                  }
                  return ListView.builder(
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final post = state.searchResults[index];
                      return ListTile(
                        key: Key('socialPostSearchItem$index'),
                        leading: CircleAvatar(
                          child: Text(post.type[0]),
                        ),
                        title: Text(post.headline ?? 'No headline'),
                        subtitle: Text('${post.type} - ${post.status}'),
                        onTap: () => Navigator.of(context).pop(post),
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
