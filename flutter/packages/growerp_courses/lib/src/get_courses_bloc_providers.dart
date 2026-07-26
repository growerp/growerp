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
