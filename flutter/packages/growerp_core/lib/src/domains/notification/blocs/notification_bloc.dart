/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
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
      debugPrint(
        'NotificationBloc: authState=${authState.status} _subscribed=$_subscribed',
      );
      if (authState.status == AuthStatus.authenticated && !_subscribed) {
        add(const NotificationFetch());
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
      if (!_subscribed && notificationClient.isConnected) {
        _subscribed = true;
        notificationClient.send("subscribe: ALL");
        notificationClient.stream().listen(
          (data) => add(
            NotificationReceive(NotificationWs.fromJson(jsonDecode(data))),
          ),
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
