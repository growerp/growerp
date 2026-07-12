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
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

part 'website_form_event.dart';
part 'website_form_state.dart';

class WebsiteFormBloc extends Bloc<WebsiteFormEvent, WebsiteFormState> {
  WebsiteFormBloc(this.restClient) : super(const WebsiteFormState()) {
    on<WebsiteFormFetch>(_onWebsiteFormFetch);
    on<WebsiteFormUpdate>(_onWebsiteFormUpdate);
    on<WebsiteFormDelete>(_onWebsiteFormDelete);
  }

  final RestClient restClient;

  Future<void> _onWebsiteFormFetch(
    WebsiteFormFetch event,
    Emitter<WebsiteFormState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteFormStatus.loading));
      WebsiteForms result = await restClient.getWebsiteForm(
        searchString: event.searchString,
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: WebsiteFormStatus.success,
          webForms: result.webForms,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteFormStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onWebsiteFormUpdate(
    WebsiteFormUpdate event,
    Emitter<WebsiteFormState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteFormStatus.loading));
      List<WebsiteForm> webForms = List.from(state.webForms);
      if (event.webForm.formId.isNotEmpty) {
        WebsiteForm result = await restClient.updateWebsiteForm(
          webForm: event.webForm,
        );
        int index = webForms.indexWhere(
          (element) => element.formId == event.webForm.formId,
        );
        webForms[index] = result;
        emit(
          state.copyWith(
            status: WebsiteFormStatus.success,
            webForms: webForms,
            message: 'form ${event.webForm.formName} updated',
          ),
        );
      } else {
        WebsiteForm result = await restClient.createWebsiteForm(
          webForm: event.webForm,
        );
        webForms.insert(0, result);
        emit(
          state.copyWith(
            status: WebsiteFormStatus.success,
            webForms: webForms,
            message: 'form ${event.webForm.formName} added',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteFormStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onWebsiteFormDelete(
    WebsiteFormDelete event,
    Emitter<WebsiteFormState> emit,
  ) async {
    try {
      emit(state.copyWith(status: WebsiteFormStatus.loading));
      List<WebsiteForm> webForms = List.from(state.webForms);
      await restClient.deleteWebsiteForm(webForm: event.webForm);
      webForms.removeWhere(
        (element) => element.formId == event.webForm.formId,
      );
      emit(
        state.copyWith(
          status: WebsiteFormStatus.success,
          webForms: webForms,
          message: 'form ${event.webForm.formName} deleted',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: WebsiteFormStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
