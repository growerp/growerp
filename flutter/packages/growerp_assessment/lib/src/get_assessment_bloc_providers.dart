import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_assessment.dart';

/// Provides BLoC instances for the assessment module with landing page support
List<BlocProvider> getAssessmentBlocProviders(RestClient restClient,
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
  ];
  return blocProviders;
}
