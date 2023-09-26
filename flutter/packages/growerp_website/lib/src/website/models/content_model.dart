/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:growerp_models/growerp_models.dart';
part 'content_model.freezed.dart';
part 'content_model.g.dart';

@freezed
class Content extends Equatable with _$Content {
  Content._();
  factory Content({
    @Default("") String path, // filename when image
    @Default("") String title,
    @Default("") String text,
    @Uint8ListConverter() Uint8List? image,
    @Default(0) int seqId,
  }) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);

  bool isText() => text.isNotEmpty;

  @override
  List<Object?> get props => [path];

  @override
  String toString() => path;
}
