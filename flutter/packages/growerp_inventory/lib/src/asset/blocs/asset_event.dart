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

class AssetSearchChanged extends AssetEvent {
  const AssetSearchChanged({
    required this.searchString,
    this.assetClassId = '',
  });
  final String searchString;
  final String assetClassId;
  @override
  List<Object> get props => [searchString, assetClassId];
}
