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

part 'department_model.freezed.dart';
part 'department_model.g.dart';

/// A department of the company: a party with the role OrgDepartment.
@freezed
abstract class Department with _$Department {
  factory Department({
    @Default("") String partyId,
    @Default("") String pseudoId,
    @Default("") String name,
    String? managerPartyId,
    String? managerName,
  }) = _Department;
  Department._();

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json['department'] ?? json);

  @override
  String toString() => 'Department: $pseudoId $name';
}
