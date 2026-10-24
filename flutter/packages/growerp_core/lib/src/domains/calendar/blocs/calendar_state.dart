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

part of 'calendar_bloc.dart';

enum CalendarStatus { initial, loading, success, failure }

class CalendarState extends Equatable {
  const CalendarState({
    this.status = CalendarStatus.initial,
    this.items = const <CalendarItem>[],
    this.calendarConnected = false,
    this.message,
  });

  final CalendarStatus status;
  final List<CalendarItem> items;

  /// The items come from the connected calendar, not from the activities.
  final bool calendarConnected;
  final String? message;

  CalendarState copyWith({
    CalendarStatus? status,
    List<CalendarItem>? items,
    bool? calendarConnected,
    String? message,
  }) {
    return CalendarState(
      status: status ?? this.status,
      items: items ?? this.items,
      calendarConnected: calendarConnected ?? this.calendarConnected,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, items, calendarConnected, message];
}
