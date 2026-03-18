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
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';

part 'email_template_event.dart';
part 'email_template_state.dart';

EventTransformer<E> emailTemplateDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class EmailTemplateBloc
    extends Bloc<EmailTemplateEvent, EmailTemplateState> {
  EmailTemplateBloc(this.restClient) : super(const EmailTemplateState()) {
    on<EmailTemplateFetch>(
      _onEmailTemplateFetch,
      transformer:
          emailTemplateDroppable(const Duration(milliseconds: 100)),
    );
    on<EmailTemplateUpdate>(_onEmailTemplateUpdate);
    on<EmailTemplateDelete>(_onEmailTemplateDelete);
  }

  final RestClient restClient;
  int start = 0;

  Future<void> _onEmailTemplateFetch(
    EmailTemplateFetch event,
    Emitter<EmailTemplateState> emit,
  ) async {
    List<EmailTemplate> current = [];
    if (state.status == EmailTemplateStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
      current = [];
    } else {
      start = state.emailTemplates.length;
      current = List.of(state.emailTemplates);
    }
    try {
      EmailTemplates result = await restClient.getEmailTemplates(
        searchString:
            event.searchString.isNotEmpty ? event.searchString : null,
      );
      emit(
        state.copyWith(
          status: EmailTemplateStatus.success,
          emailTemplates: current..addAll(result.emailTemplates),
          hasReachedMax: result.emailTemplates.length < event.limit,
          searchString: event.searchString,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: EmailTemplateStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onEmailTemplateUpdate(
    EmailTemplateUpdate event,
    Emitter<EmailTemplateState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmailTemplateStatus.loading));
      List<EmailTemplate> emailTemplates =
          List.from(state.emailTemplates);

      EmailTemplate result =
          await restClient.updateEmailTemplate(event.emailTemplate);

      int index = emailTemplates.indexWhere(
        (e) => e.emailTemplateId == event.emailTemplate.emailTemplateId,
      );
      if (index != -1) {
        emailTemplates[index] = result;
      } else {
        emailTemplates.insert(0, result);
      }

      emit(
        state.copyWith(
          status: EmailTemplateStatus.success,
          emailTemplates: emailTemplates,
          message:
              'Email template ${event.emailTemplate.emailTemplateId} updated!',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: EmailTemplateStatus.failure,
          emailTemplates: [],
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onEmailTemplateDelete(
    EmailTemplateDelete event,
    Emitter<EmailTemplateState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmailTemplateStatus.loading));
      List<EmailTemplate> emailTemplates =
          List.from(state.emailTemplates);

      await restClient.deleteEmailTemplate(event.emailTemplate);
      int index = emailTemplates.indexWhere(
        (e) => e.emailTemplateId == event.emailTemplate.emailTemplateId,
      );
      if (index != -1) {
        emailTemplates.removeAt(index);
      }
      emit(
        state.copyWith(
          status: EmailTemplateStatus.success,
          emailTemplates: emailTemplates,
          message:
              'Email template ${event.emailTemplate.emailTemplateId} deleted!',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: EmailTemplateStatus.failure,
          emailTemplates: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}
