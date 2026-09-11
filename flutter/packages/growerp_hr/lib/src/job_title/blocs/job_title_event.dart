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

part of 'job_title_bloc.dart';

abstract class JobTitleEvent extends Equatable {
  const JobTitleEvent();
  @override
  List<Object?> get props => [];
}

class JobTitlesFetch extends JobTitleEvent {
  const JobTitlesFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object> get props => [searchString, refresh];
}

class JobTitleUpdate extends JobTitleEvent {
  const JobTitleUpdate(this.jobTitle);
  final JobTitle jobTitle;
}

class JobTitleDelete extends JobTitleEvent {
  const JobTitleDelete(this.jobTitle);
  final JobTitle jobTitle;
}

class JobTitleSearchChanged extends JobTitleEvent {
  const JobTitleSearchChanged({required this.searchString});
  final String searchString;
  @override
  List<Object?> get props => [searchString];
}
