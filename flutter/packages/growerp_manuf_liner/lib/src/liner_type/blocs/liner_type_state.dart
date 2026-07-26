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
