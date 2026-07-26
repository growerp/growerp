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

import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';
part 'content_model.freezed.dart';
part 'content_model.g.dart';

@freezed
abstract class Content extends Equatable with _$Content {
  Content._();
  factory Content({
    @Default("") String path, // filename when image
    @Default("") String title,
    // SEO meta description, stored as a <!-- description: ... --> comment in text
    @Default("") String description,
    @Default("") String text,
    @Default("") String contentType, // '' or 'md' = markdown, 'ftl' = FreeMarker
    @Uint8ListConverter() Uint8List? image,
    @Default(0) int seqId,
  }) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json["content"] ?? json);

  bool isText() => text.isNotEmpty;

  @override
  List<Object?> get props => [path];

  @override
  String toString() => path;
}
