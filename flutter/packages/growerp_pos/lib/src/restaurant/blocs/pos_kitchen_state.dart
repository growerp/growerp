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

part of 'pos_kitchen_bloc.dart';

enum PosKitchenStatus { initial, success, failure }

class PosKitchenState extends Equatable {
  const PosKitchenState({
    this.status = PosKitchenStatus.initial,
    this.tickets = const <PosTicket>[],
    this.message,
  });

  final PosKitchenStatus status;
  final List<PosTicket> tickets;
  final String? message;

  PosKitchenState copyWith({
    PosKitchenStatus? status,
    List<PosTicket>? tickets,
    String? message,
  }) {
    return PosKitchenState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, tickets, message];

  @override
  String toString() => '$status { #tickets: ${tickets.length} }';
}
