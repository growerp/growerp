import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_website.dart';

List<BlocProvider> getWebsiteBlocProviders(RestClient restClient) {
  List<BlocProvider> blocProviders = [
    BlocProvider<WebsiteBloc>(create: (context) => WebsiteBloc(restClient)),
  ];
  return blocProviders;
}
