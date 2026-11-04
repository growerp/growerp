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

import 'package:growerp_core/growerp_core.dart';

import '../growerp_pos.dart';

/// Widget mappings for the point of sale package
Map<String, GrowerpWidgetBuilder> getPosWidgets() {
  return {
    'PosCheckoutScreen': (args) => const PosCheckoutScreen(),
    'PosShiftList': (args) => const PosShiftList(),
    'PosFloorScreen': (args) => const PosFloorScreen(),
    'PosKitchenScreen': (args) => const PosKitchenScreen(),
    'PosModifierGroupList': (args) => const PosModifierGroupList(),
  };
}

/// Widget metadata with icons and keywords for the point of sale package
List<WidgetMetadata> getPosWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'PosCheckoutScreen',
      description:
          'Point of sale checkout: pick or scan products, take payment '
          'and print the receipt',
      iconName: 'point_of_sale',
      keywords: ['pos', 'point of sale', 'checkout', 'till', 'cash register'],
      builder: (args) => const PosCheckoutScreen(),
    ),
    WidgetMetadata(
      widgetName: 'PosShiftList',
      description:
          'Shifts of the tills: float, cash counted, difference and the '
          'Z report of each',
      iconName: 'receipt_long',
      keywords: ['shift', 'z report', 'till', 'cash count', 'end of day'],
      builder: (args) => const PosShiftList(),
    ),
    WidgetMetadata(
      widgetName: 'PosFloorScreen',
      description: 'Floor plan of a restaurant: tables and their open tabs',
      iconName: 'table_restaurant',
      keywords: ['tables', 'floor plan', 'restaurant', 'tab'],
      builder: (args) => const PosFloorScreen(),
    ),
    WidgetMetadata(
      widgetName: 'PosKitchenScreen',
      description: 'Kitchen display: the tickets the kitchen is working on',
      iconName: 'soup_kitchen',
      keywords: ['kitchen', 'tickets', 'orders', 'cook'],
      builder: (args) => const PosKitchenScreen(),
    ),
    WidgetMetadata(
      widgetName: 'PosModifierGroupList',
      description:
          'Choices on products, like sauces or extras, with their price',
      iconName: 'tune',
      keywords: ['modifiers', 'options', 'extras', 'menu'],
      builder: (args) => const PosModifierGroupList(),
    ),
  ];
}
