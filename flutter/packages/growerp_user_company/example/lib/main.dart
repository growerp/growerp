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

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:user_company_example/router_builder.dart';

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
      title: 'GrowERP User & Company Example',
      router: createUserCompanyExampleRouter(),
      extraDelegates: const [UserCompanyLocalizations.delegate],
      extraBlocProviders: getExampleBlocProviders(restClient, applicationId),
    ),
  );
}

List<BlocProvider> getExampleBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  return [...getUserCompanyBlocProviders(restClient, applicationId)];
}
