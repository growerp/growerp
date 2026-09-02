/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:growerp_core/growerp_core.dart';

part 'notification_event.dart';
part 'notification_state.dart';

EventTransformer<E> notificationDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

int _notificationLimit = 20;

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this.restClient, this.notificationClient, this.authBloc)
    : super(const NotificationState()) {
    on<NotificationFetch>(
      _onNotificationFetch,
      // The startup fetch and the one from SetupInProgressDialog used to arrive
      // together and hit the backend twice in the same millisecond.
      transformer: notificationDroppable(const Duration(milliseconds: 500)),
    );
    on<NotificationReceive>(_onNotificationReceive);
    on<NotificationSend>(_onNotificationSend);
    // Listen once, on the client's own broadcast stream: it outlives the socket,
    // so this keeps working over a reconnect without anything re-attaching it.
    _wsSubscription = notificationClient.stream().listen(
      (data) {
        debugPrint('WS notification received: $data');
        try {
          add(NotificationReceive(NotificationWs.fromJson(jsonDecode(data))));
        } catch (e) {
          debugPrint('WS notification parse error: $e');
        }
      },
      onError: (e) => debugPrint('WS stream error: $e'),
      cancelOnError: false,
    );
    _authSubscription = authBloc.stream.listen((authState) {
      // On the transition only: while logged in every unrelated auth emission
      // would otherwise refetch.
      if (authState.status == AuthStatus.authenticated &&
          _lastAuthStatus != AuthStatus.authenticated) {
        add(const NotificationFetch());
      }
      _lastAuthStatus = authState.status;
    });
    // The provider is lazy, so this bloc is normally created after login: by then
    // the authenticated transition above has already gone by and the fetch that
    // subscribes the socket would never run, leaving every push dropped.
    _lastAuthStatus = authBloc.state.status;
    if (_lastAuthStatus == AuthStatus.authenticated) {
      add(const NotificationFetch());
    }
  }

  final RestClient restClient;
  final WsClient notificationClient;
  final AuthBloc authBloc;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _authSubscription;
  AuthStatus? _lastAuthStatus;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onNotificationFetch(
    NotificationFetch event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Idempotent and buffered until there is a socket, so a fetch that runs
      // before the connection is up no longer leaves the session unsubscribed.
      notificationClient.subscribe('ALL');

      Notifications compResult = await restClient.getNotifications(
        limit: event.limit ?? _notificationLimit,
      );
      return emit(
        state.copyWith(
          status: NotificationStatus.success,
          notifications: compResult.notifications,
          // Fetched messages must wake the same listeners as pushed ones: a
          // message the socket missed is only ever seen through a fetch.
          notificationSeq: compResult.notifications.isEmpty
              ? state.notificationSeq
              : state.notificationSeq + 1,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          notifications: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onNotificationReceive(
    NotificationReceive event,
    Emitter<NotificationState> emit,
  ) async {
    emit(
      state.copyWith(
        notifications: [event.notification],
        status: NotificationStatus.success,
        notificationSeq: state.notificationSeq + 1,
      ),
    );
  }
}

Future<void> _onNotificationSend(
  NotificationSend event,
  Emitter<NotificationState> emit,
) async {
  /*    try {
      notificationClient.send(event.notification);
      await restClient.createNotification(
          notification: Notification(
              chatRoom:
                  ChatRoom(chatRoomId: event.notification.chatRoom!.chatRoomId),
              content: event.notification.content,
              fromUserId: event.notification.fromUserId));
      List<Notification> notifications = List.from(state.notifications);
      if (notifications.isEmpty) {
        notifications.add(Notification(
          fromUserId: authBloc.state.authenticate!.user!.userId,
          content: event.notification.content,
        ));
      } else {
        notifications.insert(
            0,
            Notification(
              fromUserId: authBloc.state.authenticate!.user!.userId,
              content: event.notification.content,
            ));
      }
      emit(state.copyWith(notifications: notifications));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: NotificationStatus.failure, message: await getDioError(e)));
    }
*/
}
