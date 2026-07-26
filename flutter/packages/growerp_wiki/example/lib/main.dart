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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'router_builder.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  RestClient restClient = RestClient(await buildDioClient());
  String applicationId = GlobalConfiguration().get("applicationId");
  Bloc.observer = AppBlocObserver();

  runApp(
    TopApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: WsClient('chat'),
      notificationClient: WsClient('notws'),
      title: 'GrowERP Wiki Example',
      router: createWikiExampleRouter(),
      extraDelegates: extraDelegates,
      extraBlocProviders: getExampleBlocProviders(restClient, applicationId),
    ),
  );
}
