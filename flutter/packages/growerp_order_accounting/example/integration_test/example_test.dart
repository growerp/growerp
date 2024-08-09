import 'package:order_accounting_example/main.dart';
import 'package:patrol/patrol.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:global_configuration/global_configuration.dart';

void main() async {
  await GlobalConfiguration().loadFromAsset('app_settings');
  await Hive.initFlutter();
  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  ChatServer chatServer = ChatServer();
  Bloc.observer = AppBlocObserver();
  patrolTest(
    'counter state is the same after going to home and switching apps',
    ($) async {
      // Replace later with your app's main widget
      await TopApp(
        restClient: RestClient(await buildDioClient()),
        classificationId: 'AppAdmin',
        chatServer: chatServer,
        title: 'GrowERP Catalog.',
        router: generateRoute,
        menuOptions: menuOptions,
        extraBlocProviders:
            getOrderAccountingBlocProviders(restClient, 'AppAdmin'),
      );
    },
  );
}
