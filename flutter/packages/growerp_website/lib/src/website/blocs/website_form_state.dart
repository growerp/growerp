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

part of 'website_form_bloc.dart';

enum WebsiteFormStatus { initial, loading, success, failure }

class WebsiteFormState extends Equatable {
  const WebsiteFormState({
    this.status = WebsiteFormStatus.initial,
    this.webForms = const <WebsiteForm>[],
    this.message,
  });

  final WebsiteFormStatus status;
  final List<WebsiteForm> webForms;
  final String? message;

  WebsiteFormState copyWith({
    WebsiteFormStatus? status,
    List<WebsiteForm>? webForms,
    String? message,
  }) {
    return WebsiteFormState(
      status: status ?? this.status,
      webForms: webForms ?? this.webForms,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, message, webForms];
}
