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
  NotificationBloc(this.restClient, this.notificationServer, this.authBloc)
      : super(const NotificationState()) {
    on<NotificationFetch>(_onNotificationFetch);
    on<NotificationReceive>(_onNotificationReceive);
    on<NotificationSend>(_onNotificationSend);
  }

  final RestClient restClient;
  final WsServer notificationServer;
  final AuthBloc authBloc;

  Future<void> _onNotificationFetch(
    NotificationFetch event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.status == NotificationStatus.initial) {
      notificationServer.send("subscribe: ALL");
      final myStream = notificationServer.stream();
      myStream.listen((data) =>
          add(NotificationReceive(NotificationWs.fromJson(jsonDecode(data)))));
    }
    try {
      Notifications compResult = await restClient.getNotifications(
          limit: event.limit ?? _notificationLimit);
      return emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: compResult.notifications,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: NotificationStatus.failure,
          notifications: [],
          message: await getDioError(e)));
    }
  }

  Future<void> _onNotificationReceive(
    NotificationReceive event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    List<NotificationWs> notifications = List.from(state.notifications);
    notifications.add(event.notification);
    emit(state.copyWith(
      notifications: state.notifications,
      status: NotificationStatus.success,
    ));
  }
}

Future<void> _onNotificationSend(
  NotificationSend event,
  Emitter<NotificationState> emit,
) async {
/*    try {
      notificationServer.send(event.notification);
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
