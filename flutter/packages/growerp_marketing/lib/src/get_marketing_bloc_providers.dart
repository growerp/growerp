import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_marketing.dart';

/// Provides BLoC instances for the marketing module with landing page support
List<BlocProvider> getMarketingBlocProviders(RestClient restClient,
    [String classificationId = 'AppAdmin']) {
  List<BlocProvider> blocProviders = [
    BlocProvider<AssessmentBloc>(
      create: (context) => AssessmentBloc(restClient),
    ),
    BlocProvider<LandingPageBloc>(
      create: (context) => LandingPageBloc(
        restClient: restClient,
        classificationId: classificationId,
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
    BlocProvider<PersonaBloc>(
      create: (context) => PersonaBloc(restClient),
    ),
    BlocProvider<ContentPlanBloc>(
      create: (context) => ContentPlanBloc(restClient),
    ),
  ];
  return blocProviders;
}
