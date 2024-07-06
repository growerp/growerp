import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_inventory.dart';

List<BlocProvider> getInventoryBlocProviders(
    RestClient restClient, String classificationId) {
  List<BlocProvider> blocProviders = [
    BlocProvider<LocationBloc>(create: (context) => LocationBloc(restClient)),
    BlocProvider<AssetBloc>(
        create: (context) => AssetBloc(restClient, classificationId)),
  ];
  return blocProviders;
}
