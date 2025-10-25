import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_assessment.dart';

/// Provides BLoC instances for the assessment module
List<BlocProvider> getAssessmentBlocProviders(RestClient restClient) {
  List<BlocProvider> blocProviders = [
    BlocProvider<AssessmentBloc>(
      create: (context) => AssessmentBloc(restClient),
    ),
  ];
  return blocProviders;
}
