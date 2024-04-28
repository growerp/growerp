import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_marketing.dart';

List<BlocProvider> getMarketingBlocProviders(RestClient restClient) {
  List<BlocProvider> blocProviders = [
    BlocProvider<OpportunityBloc>(
        create: (context) => OpportunityBloc(restClient)),
  ];
  return blocProviders;
}
