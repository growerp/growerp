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

part of 'asset_bloc.dart';

enum AssetStatus { initial, loading, success, failure }

class AssetState extends Equatable {
  const AssetState({
    this.status = AssetStatus.initial,
    this.assets = const <Asset>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final AssetStatus status;
  final String? message;
  final List<Asset> assets;
  final bool hasReachedMax;
  final String searchString;

  AssetState copyWith({
    AssetStatus? status,
    String? message,
    List<Asset>? assets,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return AssetState(
      status: status ?? this.status,
      assets: assets ?? this.assets,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, assets, hasReachedMax];

  @override
  String toString() =>
      '$status { #assets: ${assets.length}, '
      'hasReachedMax: $hasReachedMax message: $message}';
}
