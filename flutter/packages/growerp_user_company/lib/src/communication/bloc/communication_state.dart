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

part of 'communication_bloc.dart';

enum CommunicationStatus { initial, loading, success, failure }

/// What a successful write did; null for a fetch, so the detail dialog only
/// closes after its own update or delete.
enum CommunicationAction { added, updated, deleted }

class CommunicationState extends Equatable {
  const CommunicationState({
    this.status = CommunicationStatus.initial,
    this.communicationEvents = const <CommunicationEvent>[],
    this.message,
    this.action,
    this.hasReachedMax = false,
  });

  final CommunicationStatus status;
  final List<CommunicationEvent> communicationEvents;
  final String? message;
  final CommunicationAction? action;
  final bool hasReachedMax;

  CommunicationState copyWith({
    CommunicationStatus? status,
    List<CommunicationEvent>? communicationEvents,
    String? message,
    CommunicationAction? action,
    bool? hasReachedMax,
  }) {
    return CommunicationState(
      status: status ?? this.status,
      communicationEvents: communicationEvents ?? this.communicationEvents,
      message: message,
      action: action,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
    status,
    communicationEvents,
    message,
    action,
    hasReachedMax,
  ];
}
