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

abstract class WebsiteFormEvent extends Equatable {
  const WebsiteFormEvent();
  @override
  List<Object> get props => [];
}

class WebsiteFormFetch extends WebsiteFormEvent {
  const WebsiteFormFetch({this.searchString = '', this.limit = 20});
  final String searchString;
  final int limit;
  @override
  List<Object> get props => [searchString];
}

class WebsiteFormUpdate extends WebsiteFormEvent {
  const WebsiteFormUpdate(this.webForm);
  final WebsiteForm webForm;
}

class WebsiteFormDelete extends WebsiteFormEvent {
  const WebsiteFormDelete(this.webForm);
  final WebsiteForm webForm;
}
