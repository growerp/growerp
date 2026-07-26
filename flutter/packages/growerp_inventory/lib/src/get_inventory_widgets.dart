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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_inventory.dart';

/// Returns widget mappings for the inventory package
Map<String, GrowerpWidgetBuilder> getInventoryWidgets() {
  return {
    'LocationList': (args) => LocationList(key: getKeyFromArgs(args)),
    'AssetList': (args) => AssetList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the inventory package
List<WidgetMetadata> getInventoryWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'LocationList',
      description: 'List of warehouse locations',
      iconName: 'location_pin',
      keywords: ['location', 'warehouse', 'storage', 'bin'],
      builder: (args) => LocationList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'AssetList',
      description: 'List of inventory assets',
      iconName: 'warehouse',
      keywords: ['asset', 'inventory', 'stock', 'equipment'],
      builder: (args) => AssetList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'LocationDialog',
      description: 'Create or edit a warehouse location. Pass locationId to '
          'edit an existing location; omit it to create a new one.',
      iconName: 'location_pin',
      keywords: ['add location', 'new location', 'create location', 'edit location'],
      parameters: {'locationId': 'open this location for editing; omit to create new'},
      builder: (args) {
        final id = (args?['locationId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return LocationDialog(Location());
        return AsyncRecordDialog<Location>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getLocation(searchString: id, limit: 1);
            return r.locations.isNotEmpty ? r.locations.first : null;
          },
          onLoaded: (l) => LocationDialog(l),
        );
      },
    ),
    WidgetMetadata(
      widgetName: 'AssetDialog',
      description: 'Create or edit an inventory asset. Pass assetId to edit an '
          'existing asset; omit it to create a new one.',
      iconName: 'warehouse',
      keywords: ['add asset', 'new asset', 'create asset', 'edit asset'],
      parameters: {'assetId': 'open this asset for editing; omit to create new'},
      builder: (args) {
        final id = (args?['assetId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return AssetDialog(Asset());
        return AsyncRecordDialog<Asset>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getAsset(assetId: id, limit: 1);
            return r.assets.isNotEmpty ? r.assets.first : null;
          },
          onLoaded: (a) => AssetDialog(a),
        );
      },
    ),
  ];
}
