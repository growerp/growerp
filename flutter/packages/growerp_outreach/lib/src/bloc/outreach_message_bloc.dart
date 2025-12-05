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

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';

import 'outreach_message_event.dart';
import 'outreach_message_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
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
    on<OutreachMessageSearchRequested>(_onSearchRequested);
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
        emit(state.copyWith(
          status: OutreachMessageStatus.loading,
          messages: [],
          hasReachedMax: false,
        ));
      }

      final result = await restClient.listOutreachMessages(
        start: event.start,
        limit: event.limit,
        campaignId: event.campaignId,
        status: event.status,
      );

      final messages = result.messages;

      emit(state.copyWith(
        status: OutreachMessageStatus.success,
        messages: event.start == 0
            ? messages
            : (List.of(state.messages)..addAll(messages)),
        hasReachedMax: messages.length < event.limit,
      ));

      start = event.start + messages.length;
    } catch (error) {
      emit(state.copyWith(
        status: OutreachMessageStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onCreate(
    OutreachMessageCreate event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      final newMessage = await restClient.createOutreachMessage(
        campaignId: event.campaignId,
        platform: event.platform,
        recipientName: event.recipientName,
        recipientProfileUrl: event.recipientProfileUrl,
        recipientHandle: event.recipientHandle,
        recipientEmail: event.recipientEmail,
        messageContent: event.messageContent,
      );

      final updatedMessages = List<OutreachMessage>.from(state.messages)
        ..insert(0, newMessage);

      emit(state.copyWith(
        status: OutreachMessageStatus.success,
        messages: updatedMessages,
        message: 'Message created successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: OutreachMessageStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onUpdateStatus(
    OutreachMessageUpdateStatus event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OutreachMessageStatus.loading));

      final updatedMessage = await restClient.updateOutreachMessageStatus(
        messageId: event.messageId,
        status: event.status,
        errorMessage: event.errorMessage,
      );

      final updatedMessages = state.messages.map((message) {
        return message.messageId == event.messageId ? updatedMessage : message;
      }).toList();

      emit(state.copyWith(
        status: OutreachMessageStatus.success,
        messages: updatedMessages,
        message: 'Message status updated',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: OutreachMessageStatus.failure,
        message: await getDioError(error),
      ));
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

      emit(state.copyWith(
        status: OutreachMessageStatus.success,
        messages: updatedMessages,
        message: 'Message deleted successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: OutreachMessageStatus.failure,
        message: await getDioError(error),
      ));
    }
  }

  Future<void> _onSearchRequested(
    OutreachMessageSearchRequested event,
    Emitter<OutreachMessageState> emit,
  ) async {
    try {
      if (event.query.isEmpty) {
        emit(state.copyWith(
          searchStatus: OutreachMessageStatus.initial,
          searchResults: [],
          searchError: null,
        ));
        return;
      }

      emit(state.copyWith(
        searchStatus: OutreachMessageStatus.loading,
        searchError: null,
      ));

      final result = await restClient.listOutreachMessages(
        start: 0,
        limit: 50,
        search: event.query,
      );

      emit(state.copyWith(
        searchStatus: OutreachMessageStatus.success,
        searchResults: result.messages,
        searchError: null,
      ));
    } catch (error) {
      emit(state.copyWith(
        searchStatus: OutreachMessageStatus.failure,
        searchError: await getDioError(error),
      ));
    }
  }
}
