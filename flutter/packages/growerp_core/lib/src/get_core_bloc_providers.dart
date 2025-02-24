import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_chat/growerp_chat.dart';

import '../growerp_core.dart';

List<BlocProvider> getCoreBlocProviders(
  RestClient restClient,
  WsClient chatClient,
  WsClient notificationClient,
  String classificationId,
  Map<String, Widget> screens,
  Company? company,
) {
  AuthBloc authBloc = AuthBloc(
      chatClient, notificationClient, restClient, classificationId, company);
  List<BlocProvider<StateStreamableSource<Object?>>> blocProviders = [
    BlocProvider<AuthBloc>(create: (context) => authBloc..add(AuthLoad())),
    BlocProvider<ThemeBloc>(
        create: (context) => ThemeBloc()..add(ThemeSwitch())),
    BlocProvider<ChatRoomBloc>(
        create: (context) => ChatRoomBloc(restClient, chatClient, authBloc)
          ..add(ChatRoomFetch())),
    BlocProvider<NotificationBloc>(
        create: (context) =>
            NotificationBloc(restClient, notificationClient, authBloc)
              ..add(const NotificationFetch())),
    BlocProvider<ChatMessageBloc>(
        create: (context) => ChatMessageBloc(restClient, chatClient, authBloc)),
    BlocProvider<TaskToDoBloc>(
        create: (context) => TaskBloc(restClient, TaskType.todo, null)),
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
    // in marketing need to search for 2 different type of users
    BlocProvider<DataFetchBlocOther<Users>>(
        create: (context) => DataFetchBloc<Users>()),
    BlocProvider<DataFetchBloc<Companies>>(
        create: (context) => DataFetchBloc<Companies>()),
    BlocProvider<DataFetchBloc<Locations>>(
        create: (context) => DataFetchBloc<Locations>()),
    BlocProvider<DataFetchBloc<Assets>>(
        create: (context) => DataFetchBloc<Assets>()),
    BlocProvider<DataFetchBloc<CompaniesUsers>>(
        create: (context) => DataFetchBloc<CompaniesUsers>()),
  ];
  return blocProviders;
}
