import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_sales.dart';

List<BlocProvider> getSalesBlocProviders(RestClient restClient) {
  List<BlocProvider> blocProviders = [
    BlocProvider<OpportunityBloc>(
      create: (context) => OpportunityBloc(restClient),
    ),
  ];
  return blocProviders;
}
