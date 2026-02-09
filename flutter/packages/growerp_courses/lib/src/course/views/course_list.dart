/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/course_bloc.dart';
import 'course_dialog.dart';
import 'course_list_styled_data.dart';

class CourseList extends StatelessWidget {
  const CourseList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CourseBloc(restClient: context.read<RestClient>())
        ..add(const CourseFetch(refresh: true)),
      child: const CourseListView(),
    );
  }
}

class CourseListView extends StatefulWidget {
  const CourseListView({super.key});

  @override
  State<CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends State<CourseListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late CourseBloc _courseBloc;
  List<Course> courses = const <Course>[];
  late double bottom;
  double? right;
  String searchString = '';
  bool _isLoading = true;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _courseBloc = context.read<CourseBloc>();
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = courses.map((course) {
        final index = courses.indexOf(course);
        return getCourseListRow(
          context: context,
          course: course,
          index: index,
          bloc: _courseBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getCourseListColumns(context),
        rows: rows,
        isLoading: _isLoading && courses.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('courseItem'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _courseBloc,
                  child: CourseDialog(course: courses[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state.status == CourseBlocStatus.failure) {
          HelperFunctions.showMessage(
            context,
            state.message ?? 'An error occurred',
            Colors.red,
          );
        }
        if (state.status == CourseBlocStatus.success) {
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
        _isLoading = state.status == CourseBlocStatus.loading;

        if (state.status == CourseBlocStatus.failure && courses.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load courses!',
          );
        }

        courses = state.courses;
        if (courses.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search courses...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _courseBloc.add(
                  CourseFetch(refresh: true, searchString: value),
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
                            heroTag: 'courseNew',
                            key: const Key('addNew'),
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _courseBloc,
                                    child: const CourseDialog(course: null),
                                  );
                                },
                              );
                            },
                            tooltip: 'Add new course',
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
    if (_isBottom) {
      _courseBloc.add(CourseFetch(searchString: searchString));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
