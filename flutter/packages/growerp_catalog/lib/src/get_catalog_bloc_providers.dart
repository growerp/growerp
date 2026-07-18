import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_catalog.dart';

List<BlocProvider> getCatalogBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  List<BlocProvider<StateStreamableSource<Object?>>> blocProviders = [
    BlocProvider<ProductBloc>(
      create: (context) => ProductBloc(restClient, applicationId),
    ),
    BlocProvider<CategoryBloc>(
      create: (context) => CategoryBloc(restClient, applicationId),
    ),
    BlocProvider<SubscriptionBloc>(
      create: (context) => SubscriptionBloc(restClient),
    ),
  ];
  return blocProviders;
}
