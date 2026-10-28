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

part of 'website_conversion_bloc.dart';

/// pollSuccess is a background refresh: same data, but views that close
/// themselves on success must ignore it.
enum WebsiteConversionStatus {
  initial,
  loading,
  success,
  pollSuccess,
  exportReady,
  failure,
}

class WebsiteConversionState extends Equatable {
  const WebsiteConversionState({
    this.status = WebsiteConversionStatus.initial,
    this.conversions = const <WebsiteConversion>[],
    this.selected,
    this.message,
    this.searchString = '',
    this.export,
  });

  final WebsiteConversionStatus status;
  final List<WebsiteConversion> conversions;

  /// single conversion including its generated password
  final WebsiteConversion? selected;
  final String? message;
  final String searchString;

  /// set once when an export is ready, so the view can offer it for saving
  final WebsiteExport? export;

  WebsiteConversionState copyWith({
    WebsiteConversionStatus? status,
    List<WebsiteConversion>? conversions,
    WebsiteConversion? selected,
    String? message,
    String? searchString,
    WebsiteExport? export,
  }) {
    return WebsiteConversionState(
      status: status ?? this.status,
      conversions: conversions ?? this.conversions,
      selected: selected ?? this.selected,
      message: message,
      searchString: searchString ?? this.searchString,
      export: export,
    );
  }

  @override
  List<Object?> get props => [status, message, conversions, selected, export];

  @override
  String toString() =>
      '$status { #conversions: ${conversions.length}, message: $message }';
}
