import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_activity/growerp_activity.dart';

import '../growerp_core.dart';

List<BlocProvider> getCoreBlocProviders(
  RestClient restClient,
  WsClient chatClient,
  WsClient notificationClient,
  String applicationId,
  Company? company,
) {
  AuthBloc authBloc = AuthBloc(
    chatClient,
    notificationClient,
    restClient,
    applicationId,
    company,
  );
  ChatRoomBloc chatRoomBloc = ChatRoomBloc(restClient, chatClient, authBloc);
  List<BlocProvider<StateStreamableSource<Object?>>> blocProviders = [
    BlocProvider<AuthBloc>(create: (context) => authBloc..add(AuthLoad())),
    BlocProvider<ChatRoomBloc>(create: (context) => chatRoomBloc),
    BlocProvider<ActivityBloc>(create: (context) => ActivityBloc(restClient)),
    // no startup event: ThemeSwitch toggles, so dispatching it here flipped
    // every cold start into dark mode. ThemeState already defaults to light.
    BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
    BlocProvider<LocaleBloc>(
      create: (context) => LocaleBloc()..add(LocaleLoaded()),
    ),
    BlocProvider<NotificationBloc>(
      // no startup fetch: it ran before there were any credentials, and racing
      // the dialog's own fetch is what made the backend insert twice
      // not lazy: created on first read it missed the login transition, so the
      // socket was never subscribed and no notification ever arrived
      lazy: false,
      create: (context) =>
          NotificationBloc(restClient, notificationClient, authBloc),
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
