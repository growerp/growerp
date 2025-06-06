import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_task.dart';

List<BlocProvider> getTaskBlocProviders(
    RestClient restClient, String classificationId) {
  List<BlocProvider> blocProviders = [
    BlocProvider<TaskBloc>(create: (context) => TaskBloc(restClient)),
  ];
  return blocProviders;
}
