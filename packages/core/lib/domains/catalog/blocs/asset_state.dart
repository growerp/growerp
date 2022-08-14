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

part of 'asset_bloc.dart';

enum AssetStatus { initial, success, failure }

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
  List<Object?> get props => [message, assets, hasReachedMax];

  @override
  String toString() => '$status { #assets: ${assets.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
