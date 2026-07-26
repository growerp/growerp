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
    on<NotificationFetch>(_onNotificationFetch);
    on<NotificationReceive>(_onNotificationReceive);
    on<NotificationSend>(_onNotificationSend);
    // Set up WS subscription once auth (and thus WS connect) completes.
    authBloc.stream.listen((authState) {
      if (authState.status == AuthStatus.authenticated && !_subscribed) {
        add(const NotificationFetch());
      } else if (authState.status == AuthStatus.unAuthenticated) {
        _subscribed = false;
      }
    });
  }

  final RestClient restClient;
  final WsClient notificationClient;
  final AuthBloc authBloc;
  bool _subscribed = false;

  Future<void> _onNotificationFetch(
    NotificationFetch event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      debugPrint(
        'NotificationFetch: _subscribed=$_subscribed '
        'isConnected=${notificationClient.isConnected}',
      );
      if (!_subscribed && notificationClient.isConnected) {
        _subscribed = true;
        try {
          notificationClient.send("subscribe: ALL");
        } catch (e) {
          debugPrint('WS subscribe send error: $e');
          _subscribed = false;
          return;
        }
        notificationClient.stream().listen(
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
      }

      Notifications compResult = await restClient.getNotifications(
        limit: event.limit ?? _notificationLimit,
      );
      return emit(
        state.copyWith(
          status: NotificationStatus.success,
          notifications: compResult.notifications,
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
