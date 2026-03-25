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

part of 'liner_type_bloc.dart';

enum LinerTypeStatus { initial, loading, success, failure }

class LinerTypeState extends Equatable {
  const LinerTypeState({
    this.status = LinerTypeStatus.initial,
    this.linerTypes = const <LinerType>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final LinerTypeStatus status;
  final String? message;
  final List<LinerType> linerTypes;
  final bool hasReachedMax;
  final String searchString;

  LinerTypeState copyWith({
    LinerTypeStatus? status,
    String? message,
    List<LinerType>? linerTypes,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return LinerTypeState(
      status: status ?? this.status,
      linerTypes: linerTypes ?? this.linerTypes,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [linerTypes, hasReachedMax, status];

  @override
  String toString() =>
      '$status { #linerTypes: ${linerTypes.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
