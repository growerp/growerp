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

part of 'application_bloc.dart';

enum ApplicationStatus { initial, loading, success, failure }

class ApplicationState extends Equatable {
  const ApplicationState({
    this.status = ApplicationStatus.initial,
    this.applications = const <Application>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final ApplicationStatus status;
  final String? message;
  final List<Application> applications;
  final bool hasReachedMax;
  final String searchString;

  ApplicationState copyWith({
    ApplicationStatus? status,
    String? message,
    List<Application>? applications,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return ApplicationState(
      status: status ?? this.status,
      applications: applications ?? this.applications,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, applications, hasReachedMax];

  @override
  String toString() =>
      '$status { #applications: ${applications.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
