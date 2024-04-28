import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_catalog.dart';

List<BlocProvider> getCatalogBlocProviders(
    RestClient restClient, String classificationId) {
  List<BlocProvider<StateStreamableSource<Object?>>> blocProviders = [
    BlocProvider<ProductBloc>(
        create: (context) => ProductBloc(restClient, classificationId)),
    BlocProvider<CategoryBloc>(
        create: (context) => CategoryBloc(restClient, classificationId)),
    BlocProvider<AssetBloc>(
        create: (context) => AssetBloc(restClient, classificationId)),
  ];
  return blocProviders;
}
