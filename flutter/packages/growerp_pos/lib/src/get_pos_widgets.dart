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
  return {'PosCheckoutScreen': (args) => const PosCheckoutScreen()};
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
  ];
}
