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

part of 'department_bloc.dart';

enum DepartmentStatus { initial, loading, success, failure }

class DepartmentState extends Equatable {
  const DepartmentState({
    this.status = DepartmentStatus.initial,
    this.departments = const <Department>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final DepartmentStatus status;
  final String? message;
  final List<Department> departments;
  final bool hasReachedMax;
  final String searchString;

  DepartmentState copyWith({
    DepartmentStatus? status,
    String? message,
    List<Department>? departments,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return DepartmentState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [departments, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #departments: ${departments.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
