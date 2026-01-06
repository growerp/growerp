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

abstract class AssetEvent extends Equatable {
  const AssetEvent();
  @override
  List<Object> get props => [];
}

class AssetFetch extends AssetEvent {
  const AssetFetch({
    this.searchString = '',
    this.refresh = false,
    this.assetClassId = '',
  });
  final String searchString;
  final bool refresh;
  final String assetClassId;
}

class AssetDelete extends AssetEvent {
  const AssetDelete(this.asset);
  final Asset asset;
}

class AssetUpdate extends AssetEvent {
  const AssetUpdate(this.asset);
  final Asset asset;
}
