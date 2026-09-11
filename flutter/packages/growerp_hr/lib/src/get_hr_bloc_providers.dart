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

import '../growerp_hr.dart';

List<BlocProvider> getHrBlocProviders(RestClient restClient) {
  return [
    BlocProvider<DepartmentBloc>(
      create: (context) => DepartmentBloc(restClient),
    ),
    BlocProvider<JobTitleBloc>(create: (context) => JobTitleBloc(restClient)),
    BlocProvider<OnboardingTaskBloc>(
      create: (context) => OnboardingTaskBloc(restClient),
    ),
    BlocProvider<EmployeeBloc>(create: (context) => EmployeeBloc(restClient)),
    BlocProvider<LeaveRequestBloc>(
      create: (context) => LeaveRequestBloc(restClient),
    ),
  ];
}
