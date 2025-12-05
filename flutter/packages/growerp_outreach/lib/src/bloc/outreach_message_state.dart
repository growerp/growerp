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
