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
import 'package:equatable/equatable.dart';

part 'account_class_model.freezed.dart';
part 'account_class_model.g.dart';

@freezed
abstract class AccountClass extends Equatable with _$AccountClass {
  const AccountClass._();
  const factory AccountClass({
    String? topClassId,
    String? topDescription,
    String? parentClassId,
    String? parentDescription,
    String? classId,
    String? description,
    String? detailClassId,
    String? detailDescription,
  }) = _AccountClass;

  factory AccountClass.fromJson(Map<String, dynamic> json) =>
      _$AccountClassFromJson(json['accountClass'] ?? json);

  @override
  List<Object?> get props => [topClassId];

  @override
  String toString() => '$topDescription[$topClassId]';
}
