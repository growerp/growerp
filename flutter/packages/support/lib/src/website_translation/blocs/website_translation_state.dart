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

/// pollSuccess is a background refresh: same data, but views that close
/// themselves on success must ignore it.
enum WebsiteTranslationStatus {
  initial,
  loading,
  success,
  pollSuccess,
  failure,
}

class WebsiteTranslationState extends Equatable {
  const WebsiteTranslationState({
    this.status = WebsiteTranslationStatus.initial,
    this.translations = const <WebsiteTranslation>[],
    this.selected,
    this.message,
    this.searchString = '',
  });

  final WebsiteTranslationStatus status;
  final List<WebsiteTranslation> translations;

  /// the row an open detail dialog shows, kept in step with the poll
  final WebsiteTranslation? selected;
  final String? message;
  final String searchString;

  WebsiteTranslationState copyWith({
    WebsiteTranslationStatus? status,
    List<WebsiteTranslation>? translations,
    WebsiteTranslation? selected,
    String? message,
    String? searchString,
  }) {
    return WebsiteTranslationState(
      status: status ?? this.status,
      translations: translations ?? this.translations,
      selected: selected ?? this.selected,
      message: message,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, translations, selected];

  @override
  String toString() =>
      '$status { #translations: ${translations.length}, message: $message }';
}
