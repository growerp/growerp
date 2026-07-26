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

part of 'gl_account_bloc.dart';

abstract class GlAccountEvent extends Equatable {
  const GlAccountEvent();
  @override
  List<Object> get props => [];
}

class GlAccountFetch extends GlAccountEvent {
  const GlAccountFetch({
    this.limit = 20,
    this.searchString = '',
    this.refresh = false,
    this.trialBalance = false,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  final bool trialBalance;
  @override
  List<Object> get props => [searchString, refresh];
}

class GlAccountSearchChanged extends GlAccountEvent {
  const GlAccountSearchChanged({
    required this.searchString,
    this.limit = 20,
    this.trialBalance = false,
  });
  final String searchString;
  final int limit;
  final bool trialBalance;
  @override
  List<Object> get props => [searchString, limit, trialBalance];
}

class GlAccountUpdate extends GlAccountEvent {
  const GlAccountUpdate(this.glAccount);
  final GlAccount glAccount;
}

class GlAccountDelete extends GlAccountEvent {
  const GlAccountDelete(this.glAccount);
  final GlAccount glAccount;
}

class GlAccountClassesFetch extends GlAccountEvent {
  const GlAccountClassesFetch({this.searchString = '', this.limit = 20});
  final String searchString;
  final int limit;
}

class GlAccountTypesFetch extends GlAccountEvent {
  const GlAccountTypesFetch({this.searchString = '', this.limit = 20});
  final String searchString;
  final int limit;
}

/// initiate a download of products by email.
class GlAccountDownload extends GlAccountEvent {}

/// start a [GlAccount] import
class GlAccountUpload extends GlAccountEvent {
  const GlAccountUpload(this.file);
  final String file;
}
