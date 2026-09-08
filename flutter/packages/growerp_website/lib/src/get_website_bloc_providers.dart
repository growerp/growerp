import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_website.dart';

List<BlocProvider> getWebsiteBlocProviders(RestClient restClient,
    [String applicationId = 'AppAdmin']) {
  List<BlocProvider> blocProviders = [
    BlocProvider<WebsiteBloc>(create: (context) => WebsiteBloc(restClient)),
    BlocProvider<WebsiteFormBloc>(
      create: (context) => WebsiteFormBloc(restClient),
    ),
    BlocProvider<AssessmentBloc>(
      create: (context) => AssessmentBloc(restClient),
    ),
    BlocProvider<LandingPageBloc>(
      create: (context) => LandingPageBloc(
        restClient: restClient,
        applicationId: applicationId,
      ),
    ),
    BlocProvider<PageSectionBloc>(
      create: (context) => PageSectionBloc(restClient: restClient),
    ),
    BlocProvider<CredibilityBloc>(
      create: (context) => CredibilityBloc(restClient: restClient),
    ),
    BlocProvider<QuestionBloc>(
      create: (context) => QuestionBloc(restClient: restClient),
    ),
  ];
  return blocProviders;
}
