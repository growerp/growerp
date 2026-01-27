/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'course/bloc/course_bloc.dart';
import 'media/bloc/course_media_bloc.dart';
import 'viewer/bloc/course_viewer_bloc.dart';

/// Returns BLoC providers for the courses package
List<BlocProvider> getCoursesBlocProviders(RestClient restClient) {
  return [
    BlocProvider<CourseBloc>(
      create: (context) => CourseBloc(restClient: restClient),
    ),
    BlocProvider<CourseMediaBloc>(
      create: (context) => CourseMediaBloc(restClient: restClient),
    ),
    BlocProvider<CourseViewerBloc>(
      create: (context) => CourseViewerBloc(restClient: restClient),
    ),
  ];
}
