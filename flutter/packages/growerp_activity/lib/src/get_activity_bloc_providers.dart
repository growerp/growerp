import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_activity.dart';

List<BlocProvider> getActivityBlocProviders(
  RestClient restClient,
  String classificationId,
) {
  List<BlocProvider> blocProviders = [
    BlocProvider<ActivityBloc>(create: (context) => ActivityBloc(restClient)),
  ];
  return blocProviders;
}
