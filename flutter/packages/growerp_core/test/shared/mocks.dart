export 'package:growerp_models/testing.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:mocktail/mocktail.dart';

class MockWsClient extends Mock implements WsClient {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockChatRoomBloc extends MockBloc<ChatRoomEvent, ChatRoomState>
    implements ChatRoomBloc {}
