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
