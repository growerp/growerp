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

import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum OutreachMessageStatus { initial, loading, success, failure }

class OutreachMessageState extends Equatable {
  const OutreachMessageState({
    this.status = OutreachMessageStatus.initial,
    this.messages = const <OutreachMessage>[],
    this.hasReachedMax = false,
    this.message,
    this.searchStatus = OutreachMessageStatus.initial,
    this.searchResults = const <OutreachMessage>[],
    this.searchError,
  });

  final OutreachMessageStatus status;
  final List<OutreachMessage> messages;
  final bool hasReachedMax;
  final String? message;
  final OutreachMessageStatus searchStatus;
  final List<OutreachMessage> searchResults;
  final String? searchError;

  OutreachMessageState copyWith({
    OutreachMessageStatus? status,
    List<OutreachMessage>? messages,
    bool? hasReachedMax,
    String? message,
    OutreachMessageStatus? searchStatus,
    List<OutreachMessage>? searchResults,
    String? searchError,
  }) {
    return OutreachMessageState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      message: message,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      searchError: searchError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        hasReachedMax,
        message,
        searchStatus,
        searchResults,
        searchError,
      ];

  @override
  String toString() {
    return '''OutreachMessageState {
      status: $status,
      messages: ${messages.length},
      hasReachedMax: $hasReachedMax,
      message: $message,
      searchStatus: $searchStatus,
      searchResults: ${searchResults.length},
      searchError: $searchError,
    }''';
  }
}
