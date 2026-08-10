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

/// pollSuccess is a background refresh: same data, but views that close
/// themselves on success must ignore it.
enum GlAccountTranslationStatus {
  initial,
  loading,
  success,
  pollSuccess,
  failure,
}

class GlAccountTranslationState extends Equatable {
  const GlAccountTranslationState({
    this.status = GlAccountTranslationStatus.initial,
    this.translations = const <GlAccountTranslation>[],
    this.message,
    this.searchString = '',
  });

  final GlAccountTranslationStatus status;
  final List<GlAccountTranslation> translations;
  final String? message;
  final String searchString;

  GlAccountTranslationState copyWith({
    GlAccountTranslationStatus? status,
    List<GlAccountTranslation>? translations,
    String? message,
    String? searchString,
  }) {
    return GlAccountTranslationState(
      status: status ?? this.status,
      translations: translations ?? this.translations,
      message: message,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, translations];

  @override
  String toString() =>
      '$status { #translations: ${translations.length}, message: $message }';
}
