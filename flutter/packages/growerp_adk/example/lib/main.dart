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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'router_builder.dart';

/// Standalone GrowERP ADK application — composes the growerp_adk building
/// block (agents, jobs, chat, governance) on a static menu/router so it runs
/// without a backend-seeded menu.
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');
  String applicationId = GlobalConfiguration().get("applicationId");

  runApp(
    TopApp(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP ADK',
      router: createAdkExampleRouter(),
      extraDelegates: const [UserCompanyLocalizations.delegate],
      extraBlocProviders: getUserCompanyBlocProviders(
        restClient,
        applicationId,
      ),
    ),
  );
}
