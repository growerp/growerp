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

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const <NotificationWs>[],
    this.message,
    this.notificationSeq = 0,
  });

  final NotificationStatus status;
  final String? message;
  final List<NotificationWs> notifications;
  final int notificationSeq;

  NotificationState copyWith({
    NotificationStatus? status,
    String? message,
    List<NotificationWs>? notifications,
    int? notificationSeq,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      message: message,
      notificationSeq: notificationSeq ?? this.notificationSeq,
    );
  }

  @override
  List<Object?> get props => [notifications, status, notificationSeq];

  @override
  String toString() =>
      '$status { #notifications: ${notifications.length}, '
      ' message $message}';
}
