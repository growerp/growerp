import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_chat/growerp_chat.dart';
import 'package:growerp_activity/growerp_activity.dart';

import '../growerp_core.dart';

List<BlocProvider> getCoreBlocProviders(
  RestClient restClient,
  WsClient chatClient,
  WsClient notificationClient,
  String classificationId,
  Company? company,
) {
  AuthBloc authBloc = AuthBloc(
    chatClient,
    notificationClient,
    restClient,
    classificationId,
    company,
  );
  ChatRoomBloc chatRoomBloc = ChatRoomBloc(restClient, chatClient, authBloc);
  List<BlocProvider<StateStreamableSource<Object?>>> blocProviders = [
    BlocProvider<AuthBloc>(create: (context) => authBloc..add(AuthLoad())),
    BlocProvider<ChatRoomBloc>(
      create: (context) =>
          ChatRoomBloc(restClient, chatClient, authBloc)
            ..add(const ChatRoomFetch()),
    ),
    BlocProvider<ActivityBloc>(create: (context) => ActivityBloc(restClient)),
    BlocProvider<ThemeBloc>(
      create: (context) => ThemeBloc()..add(ThemeSwitch()),
    ),
    BlocProvider<LocaleBloc>(
      create: (context) => LocaleBloc()..add(LocaleLoaded()),
    ),
    BlocProvider<NotificationBloc>(
      create: (context) =>
          NotificationBloc(restClient, notificationClient, authBloc)
            ..add(const NotificationFetch()),
    ),
    BlocProvider<ChatMessageBloc>(
      create: (context) =>
          ChatMessageBloc(restClient, chatClient, authBloc, chatRoomBloc),
    ),
    BlocProvider<DataFetchBloc<Activities>>(
      create: (context) => DataFetchBloc<Activities>(),
    ),
    BlocProvider<DataFetchBloc<FinDocs>>(
      create: (context) => DataFetchBloc<FinDocs>(),
    ),
    BlocProvider<DataFetchBloc<Products>>(
      create: (context) => DataFetchBloc<Products>(),
    ),
    BlocProvider<DataFetchBloc<Categories>>(
      create: (context) => DataFetchBloc<Categories>(),
    ),
    BlocProvider<DataFetchBloc<Users>>(
      create: (context) => DataFetchBloc<Users>(),
    ),
    // in marketing need to search for 2 different type of users
    BlocProvider<DataFetchBlocOther<Users>>(
      create: (context) => DataFetchBloc<Users>(),
    ),
    BlocProvider<DataFetchBloc<Companies>>(
      create: (context) => DataFetchBloc<Companies>(),
    ),
    BlocProvider<DataFetchBloc<Locations>>(
      create: (context) => DataFetchBloc<Locations>(),
    ),
    BlocProvider<DataFetchBloc<Assets>>(
      create: (context) => DataFetchBloc<Assets>(),
    ),
    BlocProvider<DataFetchBloc<CompaniesUsers>>(
      create: (context) => DataFetchBloc<CompaniesUsers>(),
    ),
    BlocProvider<DataFetchBloc<Subscriptions>>(
      create: (context) => DataFetchBloc<Subscriptions>(),
    ),
  ];
  return blocProviders;
}
