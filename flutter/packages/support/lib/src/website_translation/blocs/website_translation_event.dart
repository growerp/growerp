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

part of 'website_translation_bloc.dart';

abstract class WebsiteTranslationEvent extends Equatable {
  const WebsiteTranslationEvent();
  @override
  List<Object> get props => [];
}

class WebsiteTranslationFetch extends WebsiteTranslationEvent {
  const WebsiteTranslationFetch({
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

class WebsiteTranslationCreate extends WebsiteTranslationEvent {
  const WebsiteTranslationCreate({
    required this.ownerPartyId,
    required this.targetLocales,
    this.sourceLocale = 'en',
    this.translateEntityNames = false,
    this.overwriteExisting = false,
  });

  final String ownerPartyId;

  /// comma separated, eg 'th,nl'
  final String targetLocales;
  final String sourceLocale;
  final bool translateEntityNames;
  final bool overwriteExisting;

  @override
  List<Object> get props => [
    ownerPartyId,
    targetLocales,
    sourceLocale,
    translateEntityNames,
    overwriteExisting,
  ];
}

class WebsiteTranslationDelete extends WebsiteTranslationEvent {
  const WebsiteTranslationDelete(this.translation);
  final WebsiteTranslation translation;
  @override
  List<Object> get props => [translation];
}
