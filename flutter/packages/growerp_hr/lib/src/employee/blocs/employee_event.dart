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

abstract class EmployeeEvent extends Equatable {
  const EmployeeEvent();
  @override
  List<Object?> get props => [];
}

class EmployeesFetch extends EmployeeEvent {
  const EmployeesFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
    this.partyId,
  });
  final String searchString;
  final bool refresh;
  final int limit;

  /// when set only this employee is fetched, used by the self service screen
  final String? partyId;
  @override
  List<Object?> get props => [searchString, refresh, partyId];
}

class EmployeeUpdate extends EmployeeEvent {
  const EmployeeUpdate(this.employee);
  final Employee employee;
}

class EmployeeOnboardingTaskUpdate extends EmployeeEvent {
  const EmployeeOnboardingTaskUpdate({
    required this.partyId,
    required this.onboardingTaskId,
    required this.completed,
  });
  final String partyId;
  final String onboardingTaskId;
  final bool completed;
}

class EmployeeSearchChanged extends EmployeeEvent {
  const EmployeeSearchChanged({required this.searchString, this.partyId});
  final String searchString;
  final String? partyId;
  @override
  List<Object?> get props => [searchString, partyId];
}
