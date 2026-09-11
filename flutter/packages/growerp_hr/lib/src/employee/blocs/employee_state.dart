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

part of 'employee_bloc.dart';

/// Bloc status; named to avoid a clash with the [EmployeeStatus] of the model.
enum EmployeeStatusBloc { initial, loading, success, checklistSuccess, failure }

class EmployeeState extends Equatable {
  const EmployeeState({
    this.status = EmployeeStatusBloc.initial,
    this.employees = const <Employee>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final EmployeeStatusBloc status;
  final String? message;
  final List<Employee> employees;
  final bool hasReachedMax;
  final String searchString;

  EmployeeState copyWith({
    EmployeeStatusBloc? status,
    String? message,
    List<Employee>? employees,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [employees, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #employees: ${employees.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
