import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_marketing.dart';

/// Provides BLoC instances for the marketing module
/// [applicationId] is accepted for call-site compatibility; the marketing blocs
/// no longer need it since landing pages moved to growerp_website.
List<BlocProvider> getMarketingBlocProviders(RestClient restClient,
    [String applicationId = 'AppAdmin']) {
  List<BlocProvider> blocProviders = [
    BlocProvider<PersonaBloc>(
      create: (context) => PersonaBloc(restClient),
    ),
    BlocProvider<EmailSequenceBloc>(
      create: (context) => EmailSequenceBloc(restClient),
    ),
    BlocProvider<ContentPlanBloc>(
      create: (context) => ContentPlanBloc(restClient),
    ),
    BlocProvider<SocialPostBloc>(
      create: (context) => SocialPostBloc(restClient),
    ),
    BlocProvider<MasterContentBloc>(
      create: (context) => MasterContentBloc(restClient),
    ),
  ];
  return blocProviders;
}
