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

part 'obsidian_model.freezed.dart';
part 'obsidian_model.g.dart';

@freezed
abstract class Obsidian extends Equatable with _$Obsidian {
  Obsidian._();
  factory Obsidian({
    @Default("") String title,
    @Uint8ListConverter() Uint8List? zip,
  }) = _Obsidian;

  factory Obsidian.fromJson(Map<String, dynamic> json) =>
      _$ObsidianFromJson(json['obsidian'] ?? json);

  @override
  List<Object?> get props => [title];

  @override
  String toString() => title;
}
