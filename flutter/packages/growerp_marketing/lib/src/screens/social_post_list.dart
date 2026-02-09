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

import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';
import '../bloc/social_post_state.dart';
import 'social_post_detail_screen.dart';
import 'social_post_list_styled_data.dart';

/// List screen for Social Posts
class SocialPostList extends StatefulWidget {
  const SocialPostList({super.key});

  @override
  SocialPostListState createState() => SocialPostListState();
}

class SocialPostListState extends State<SocialPostList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late SocialPostBloc _socialPostBloc;
  List<SocialPost> socialPosts = const <SocialPost>[];
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
    _socialPostBloc = context.read<SocialPostBloc>()
      ..add(const SocialPostFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = socialPosts.map((post) {
        final index = socialPosts.indexOf(post);
        return getSocialPostListRow(
          context: context,
          post: post,
          index: index,
          bloc: _socialPostBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getSocialPostListColumns(context),
        rows: rows,
        isLoading: _isLoading && socialPosts.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('socialPostDetailScreen'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _socialPostBloc,
                  child: SocialPostDetailScreen(
                    socialPost: socialPosts[index],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<SocialPostBloc, SocialPostState>(
      listener: (context, state) {
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
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == SocialPostStatus.loading;

        if (state.status == SocialPostStatus.failure && socialPosts.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load social posts!',
          );
        }

        socialPosts = state.socialPosts;
        if (socialPosts.isNotEmpty && _scrollController.hasClients) {
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
              searchHint: 'Search social posts...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _socialPostBloc.add(
                  SocialPostFetch(refresh: true, searchString: value),
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
                            key: const Key('addNewSocialPost'),
                            heroTag: 'socialPostBtn1',
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
      _socialPostBloc.add(
        SocialPostFetch(start: socialPosts.length, searchString: searchString),
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
