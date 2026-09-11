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

enum JobTitleStatus { initial, loading, success, failure }

class JobTitleState extends Equatable {
  const JobTitleState({
    this.status = JobTitleStatus.initial,
    this.jobTitles = const <JobTitle>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final JobTitleStatus status;
  final String? message;
  final List<JobTitle> jobTitles;
  final bool hasReachedMax;
  final String searchString;

  JobTitleState copyWith({
    JobTitleStatus? status,
    String? message,
    List<JobTitle>? jobTitles,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return JobTitleState(
      status: status ?? this.status,
      jobTitles: jobTitles ?? this.jobTitles,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [jobTitles, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #jobTitles: ${jobTitles.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
