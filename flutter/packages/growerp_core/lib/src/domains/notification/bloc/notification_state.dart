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

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const <NotificationWs>[],
    this.message,
  });

  final NotificationStatus status;
  final String? message;
  final List<NotificationWs> notifications;

  NotificationState copyWith({
    NotificationStatus? status,
    String? message,
    List<NotificationWs>? notifications,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      message: message,
    );
  }

  @override
  List<Object?> get props => [notifications, status];

  @override
  String toString() => '$status { #notifications: ${notifications.length}, '
      ' message $message}';
}
