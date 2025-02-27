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

part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object> get props => [];
}

class NotificationFetch extends NotificationEvent {
  const NotificationFetch({this.limit = 20});
  final int? limit;
}

class NotificationReceive extends NotificationEvent {
  final NotificationWs notification;
  const NotificationReceive(this.notification);
  @override
  String toString() =>
      "ReceiveWsNotification: receive notification: ${notification.message?['message']}";
}

class NotificationSend extends NotificationEvent {
  final NotificationWs notification;
  const NotificationSend(this.notification);
  @override
  String toString() => "SendWsNotification send wsChat message: $notification";
}
