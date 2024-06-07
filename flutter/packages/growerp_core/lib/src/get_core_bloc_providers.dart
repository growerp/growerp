import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../growerp_core.dart';

List<BlocProvider> getCoreBlocProviders(
    RestClient restClient,
    ChatServer chatServer,
    String classificationId,
    Map<String, Widget> screens) {
  AuthBloc authBloc = AuthBloc(chatServer, restClient, classificationId);

  List<BlocProvider<StateStreamableSource<Object?>>> blocProviders = [
    BlocProvider<AuthBloc>(create: (context) => authBloc..add(AuthLoad())),
    BlocProvider<ThemeBloc>(
        create: (context) => ThemeBloc()..add(ThemeSwitch())),
    BlocProvider<ChatRoomBloc>(
        create: (context) => ChatRoomBloc(restClient, chatServer, authBloc)
          ..add(ChatRoomFetch())),
    BlocProvider<ChatMessageBloc>(
        create: (context) => ChatMessageBloc(restClient, chatServer, authBloc)),
    BlocProvider<TaskWorkflowBloc>(
        create: (context) => TaskBloc(restClient, TaskType.workflow, null)),
    BlocProvider<TaskWorkflowTemplateBloc>(
        create: (context) =>
            TaskBloc(restClient, TaskType.workflowTemplate, screens)),
    BlocProvider<DataFetchBloc<FinDocs>>(
        create: (context) => DataFetchBloc<FinDocs>()),
    BlocProvider<DataFetchBloc<Products>>(
        create: (context) => DataFetchBloc<Products>()),
    BlocProvider<DataFetchBloc<Categories>>(
        create: (context) => DataFetchBloc<Categories>()),
    BlocProvider<DataFetchBloc<Users>>(
        create: (context) => DataFetchBloc<Users>()),
    BlocProvider<DataFetchBlocOther<Users>>(
        create: (context) => DataFetchBloc<Users>()),
    BlocProvider<DataFetchBloc<Companies>>(
        create: (context) => DataFetchBloc<Companies>()),
    BlocProvider<DataFetchBloc<Locations>>(
        create: (context) => DataFetchBloc<Locations>()),
  ];
  return blocProviders;
}
