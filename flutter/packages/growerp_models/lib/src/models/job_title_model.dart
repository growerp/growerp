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

part 'job_title_model.freezed.dart';
part 'job_title_model.g.dart';

@freezed
abstract class JobTitle with _$JobTitle {
  factory JobTitle({
    @Default("") String jobTitleId,
    @Default("") String pseudoId,
    @Default("") String title,
    String? description,
  }) = _JobTitle;
  JobTitle._();

  factory JobTitle.fromJson(Map<String, dynamic> json) =>
      _$JobTitleFromJson(json['jobTitle'] ?? json);

  @override
  String toString() => 'JobTitle: $pseudoId $title';
}
