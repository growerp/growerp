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
