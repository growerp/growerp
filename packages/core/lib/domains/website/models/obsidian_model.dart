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

import '../../../services/jsonConverters.dart';

part 'obsidian_model.freezed.dart';
part 'obsidian_model.g.dart';

@freezed
class Obsidian extends Equatable with _$Obsidian {
  Obsidian._();
  factory Obsidian({
    @Default("") String title,
    @Uint8ListConverter() Uint8List? zip,
  }) = _Obsidian;

  factory Obsidian.fromJson(Map<String, dynamic> json) =>
      _$ObsidianFromJson(json);

  @override
  List<Object?> get props => [title];

  @override
  String toString() => '$title';
}
