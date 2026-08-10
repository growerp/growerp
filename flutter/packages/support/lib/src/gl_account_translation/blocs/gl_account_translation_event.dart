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

part of 'gl_account_translation_bloc.dart';

abstract class GlAccountTranslationEvent extends Equatable {
  const GlAccountTranslationEvent();
  @override
  List<Object> get props => [];
}

class GlAccountTranslationFetch extends GlAccountTranslationEvent {
  const GlAccountTranslationFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
    this.background = false,
  });

  final String searchString;
  final bool refresh;
  final int limit;

  /// a poll while a translation is running: must not disturb an open dialog
  final bool background;

  @override
  List<Object> get props => [searchString, refresh, background];
}

class GlAccountTranslationCreate extends GlAccountTranslationEvent {
  const GlAccountTranslationCreate({
    required this.targetLocale,
    this.sourceLocale = 'en',
  });

  /// one language per run, eg 'nl'
  final String targetLocale;

  /// the language the stored account names are in: en for the standard chart,
  /// the upload language when a company uploaded its own
  final String sourceLocale;

  @override
  List<Object> get props => [targetLocale, sourceLocale];
}

class GlAccountTranslationDelete extends GlAccountTranslationEvent {
  const GlAccountTranslationDelete(this.translation);
  final GlAccountTranslation translation;
  @override
  List<Object> get props => [translation];
}
