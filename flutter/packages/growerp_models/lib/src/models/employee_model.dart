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

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../growerp_models.dart';

part 'employee_model.freezed.dart';
part 'employee_model.g.dart';

/// An employee: the person with a PrtEmployee relation to the company,
/// extended with the HR fields and the onboarding checklist.
@freezed
abstract class Employee with _$Employee {
  factory Employee({
    @Default("") String partyId,
    @Default("") String pseudoId,
    @Default("") String firstName,
    @Default("") String lastName,
    String? email,
    String? loginName,
    String? jobTitleId,
    String? jobTitle,
    String? departmentPartyId,
    String? department,
    String? managerPartyId,
    String? managerName,
    @DateTimeConverter() DateTime? hireDate,
    @JsonKey(name: 'statusId')
    @EmployeeStatusConverter()
    EmployeeStatus? status,
    @Default([]) List<OnboardingTask> onboardingTasks,
  }) = _Employee;
  Employee._();

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json['employee'] ?? json);

  String get name => '$firstName $lastName'.trim();

  @override
  String toString() => 'Employee: $partyId $firstName $lastName';
}
