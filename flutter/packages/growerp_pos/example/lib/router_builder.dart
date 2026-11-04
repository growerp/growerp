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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_pos/growerp_pos.dart';
import 'package:growerp_user_company/growerp_user_company.dart';

/// Canonical menu configuration for the point of sale example app, used by the
/// app and by the integration tests.
const posMenuConfig = MenuConfiguration(
  menuConfigurationId: 'POS_EXAMPLE',
  appId: 'pos_example',
  name: 'POS Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'POS_CHECKOUT',
      title: 'Checkout',
      route: '/',
      iconName: 'point_of_sale',
      sequenceNum: 10,
      widgetName: 'PosCheckoutScreen',
    ),
  ],
);

GoRouter createPosExampleRouter() {
  return createStaticAppRouter(
    menuConfig: posMenuConfig,
    appTitle: 'GrowERP POS Example',
    dashboard: const PosCheckoutScreen(),
    widgetBuilder: (route) => const PosCheckoutScreen(),
  );
}

/// The same for a restaurant: floor first, kitchen beside it.
const restaurantMenuConfig = MenuConfiguration(
  menuConfigurationId: 'RESTAURANT_EXAMPLE',
  appId: 'restaurant_example',
  name: 'Restaurant Example Menu',
  menuItems: [
    MenuItem(
      itemKey: 'RESTAURANT_FLOOR',
      title: 'Floor',
      route: '/',
      iconName: 'table_restaurant',
      sequenceNum: 10,
      widgetName: 'PosFloorScreen',
    ),
    MenuItem(
      itemKey: 'RESTAURANT_KITCHEN',
      title: 'Kitchen',
      route: '/kitchen',
      iconName: 'soup_kitchen',
      sequenceNum: 20,
      widgetName: 'PosKitchenScreen',
    ),
  ],
);

GoRouter createRestaurantExampleRouter() {
  return createStaticAppRouter(
    menuConfig: restaurantMenuConfig,
    appTitle: 'GrowERP Restaurant Example',
    dashboard: const PosFloorScreen(),
    widgetBuilder: (route) => switch (route) {
      '/kitchen' => const PosKitchenScreen(),
      _ => const PosFloorScreen(),
    },
  );
}

/// BLoC providers for the point of sale example app.
List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [
    ...getUserCompanyBlocProviders(restClient, applicationId),
    ...getPosBlocProviders(restClient),
  ];
}

/// Localizations delegates for the point of sale example app.
List<LocalizationsDelegate<dynamic>> extraDelegates = const [
  UserCompanyLocalizations.delegate,
  PosLocalizations.delegate,
];
