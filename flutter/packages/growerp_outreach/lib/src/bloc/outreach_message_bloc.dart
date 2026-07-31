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

import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

import 'outreach_message_event.dart';
import 'outreach_message_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

const _outreachSearchDebounceDuration = Duration(milliseconds: 300);
EventTransformer<OutreachMessageSearchRequested>
outreachMessageSearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.query.isEmpty);
    final searchStream = events
        .where((e) => e.query.length >= 3)
        .debounce(_outreachSearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class OutreachMessageBloc
    extends Bloc<OutreachMessageEvent, OutreachMessageState> {
  OutreachMessageBloc(this.restClient) : super(const OutreachMessageState()) {
    on<OutreachMessageLoad>(
      _onLoad,
      transformer: throttleDroppable(_throttleDuration),
    );
    on<OutreachMessageCreate>(_onCreate);
    on<OutreachMessageUpdateStatus>(_onUpdateStatus);
    on<OutreachMessageDelete>(_onDelete);
    on<OutreachMessageRetry>(_onRetry);
    on<OutreachMessageSearchRequested>(
      _onSearchRequested,
      transformer: outreachMessageSearchDebounce(),
    );
    on<OutreachMessageConvertToLead>(_onConvertToLead);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onLoad(
    OutreachMessageLoad event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      if (state.hasReachedMax && event.start != 0) return;

      if (event.start == 0) {
        emit(
          state.copyWith(
            status: OutreachMessageStatus.loading,
            messages: [],
            hasReachedMax: false,
          ),
        );
      }

      final result = await restClient.listOutreachMessages(
        start: event.start,
        limit: event.limit,
        marketingCampaignId: event.campaignId,
        status: event.status,
      );

      final messages = result.messages;

      emit(
        state.copyWith(
          status: OutreachMessageStatus.success,
          messages: event.start == 0
              ? messages
              : (List.of(state.messages)..addAll(messages)),
          hasReachedMax: messages.length < event.limit,
        ),
      );

      start = event.start + messages.length;
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachMessageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onCreate(
    OutreachMessageCreate event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      final newMessage = await restClient.createOutreachMessage(
        marketingCampaignId: event.campaignId,
        platform: event.platform,
        recipientName: event.recipientName,
        recipientProfileUrl: event.recipientProfileUrl,
        recipientHandle: event.recipientHandle,
        recipientEmail: event.recipientEmail,
        messageContent: event.messageContent,
        emailSubject: event.emailSubject,
      );

      final updatedMessages = List<OutreachMessage>.from(state.messages)
        ..insert(0, newMessage);

      emit(
        state.copyWith(
          status: OutreachMessageStatus.success,
          messages: updatedMessages,
          message: 'Message created successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachMessageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onUpdateStatus(
    OutreachMessageUpdateStatus event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      // body/subject live on a separate endpoint which only accepts PENDING
      // messages, so the caller only passes them while still editable
      if (event.messageContent != null) {
        await restClient.updateOutreachMessageContent(
          messageId: event.messageId,
          messageContent: event.messageContent!,
          emailSubject: event.emailSubject,
        );
      }

      final updatedMessage = await restClient.updateOutreachMessageStatus(
        messageId: event.messageId,
        status: event.status,
        errorMessage: event.errorMessage,
      );

      final updatedMessages = state.messages.map((message) {
        return message.messageId == event.messageId ? updatedMessage : message;
      }).toList();

      emit(
        state.copyWith(
          status: OutreachMessageStatus.success,
          messages: updatedMessages,
          message: 'Message status updated',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachMessageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onDelete(
    OutreachMessageDelete event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      await restClient.deleteOutreachMessage(messageId: event.messageId);

      final updatedMessages = state.messages
          .where((message) => message.messageId != event.messageId)
          .toList();

      emit(
        state.copyWith(
          status: OutreachMessageStatus.success,
          messages: updatedMessages,
          message: 'Message deleted successfully',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachMessageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onRetry(
    OutreachMessageRetry event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      final result = await restClient.retryOutreachMessages(
        messageId: event.messageId,
        marketingCampaignId: event.campaignId,
      );
      // dio can hand the body back as a raw JSON String
      final decoded = result is String ? jsonDecode(result) : result;
      final count = decoded['retriedCount'] ?? 0;

      final refreshed = await restClient.listOutreachMessages(
        start: 0,
        limit: 20,
        marketingCampaignId: event.campaignId,
      );

      emit(
        state.copyWith(
          status: OutreachMessageStatus.success,
          messages: refreshed.messages,
          hasReachedMax: refreshed.messages.length < 20,
          message: '$count message(s) requeued',
        ),
      );
      start = refreshed.messages.length;
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachMessageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }

  Future<void> _onSearchRequested(
    OutreachMessageSearchRequested event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      if (event.query.isEmpty) {
        emit(
          state.copyWith(
            searchStatus: OutreachMessageStatus.initial,
            searchResults: [],
            searchError: null,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          searchStatus: OutreachMessageStatus.loading,
          searchError: null,
        ),
      );

      final result = await restClient.listOutreachMessages(
        start: 0,
        limit: 50,
        search: event.query,
      );

      emit(
        state.copyWith(
          searchStatus: OutreachMessageStatus.success,
          searchResults: result.messages,
          searchError: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          searchStatus: OutreachMessageStatus.failure,
          searchError: await getDioError(error),
        ),
      );
    }
  }

  /// Convert a cold-outreach prospect into a GrowERP lead.
  ///
  /// Lifecycle:
  ///   OutreachMessage(status: PENDING|RESPONDED)
  ///     ↓  create User(role: lead)   via POST /User
  ///     ↓  stamp convertedPartyId    via PATCH /OutreachMessage
  ///   OutreachMessage(status: CONVERTED, convertedPartyId: `<partyId>`)
  ///     ↓  standard CRM pipeline
  ///   Opportunity(stage: Prospecting, leadUser: `<partyId>`)
  Future<void> _onConvertToLead(
    OutreachMessageConvertToLead event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      // 1. Create the GrowERP lead record
      final newLead = await restClient.createUser(
        user: User(
          firstName: event.firstName,
          lastName: event.lastName ?? '',
          email: event.email ?? '',
          loginName: event.email ?? '',
          role: Role.lead,
          company: event.companyName != null
              ? Company(name: event.companyName!, role: Role.lead)
              : null,
        ),
      );

      final partyId = newLead.partyId;

      // 2. Stamp the OutreachMessage with CONVERTED + the new partyId
      final updated = await restClient.updateOutreachMessageStatus(
        messageId: event.messageId,
        status: 'CONVERTED',
        convertedPartyId: partyId,
      );

      final updatedMessages = state.messages.map((m) {
        return m.messageId == event.messageId ? updated : m;
      }).toList();

      emit(
        state.copyWith(
          status: OutreachMessageStatus.success,
          messages: updatedMessages,
          message:
              'Prospect converted to lead'
              '${partyId != null ? " ($partyId)" : ""}',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OutreachMessageStatus.failure,
          message: await getDioError(error),
        ),
      );
    }
  }
}
