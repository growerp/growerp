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

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../growerp_models.dart';

part 'website_conversion_model.freezed.dart';
part 'website_conversion_model.g.dart';

/// One run of the website generator: scrape an existing site, write the pages with
/// AI and install them as a new owner. Runs in the background, so this record is
/// polled for progress.
@freezed
abstract class WebsiteConversion with _$WebsiteConversion {
  factory WebsiteConversion({
    @Default('') String conversionId,
    @Default('') String sourceUrl,
    @Default('') String siteId,
    @Default('') String companyName,
    @Default('') String adminEmail,
    @Default('') String adminFirstName,
    @Default('') String adminLastName,
    @Default('') String currencyId,
    @Default('') String applicationId,
    @Default('') String hostNames, // comma separated
    int? maxPages,
    // QUEUED, SCRAPING, GENERATING, IMPORTING, COMPLETED, FAILED
    @Default('') String status,
    @Default('') String statusMessage,
    int? pageCount,
    int? imageCount,
    @Default('') String createdOwnerPartyId,
    @Default('') String createdCompanyPartyId,
    @Default('') String productStoreId,
    // only returned when a single conversion is fetched
    @Default('') String generatedPassword,
    @Default('') String errorMessage,
    @DateTimeConverter() DateTime? createdDate,
    @DateTimeConverter() DateTime? completedDate,
  }) = _WebsiteConversion;
  WebsiteConversion._();

  factory WebsiteConversion.fromJson(Map<String, dynamic> json) =>
      _$WebsiteConversionFromJson(json['websiteConversion'] ?? json);

  /// still working, so the list keeps polling
  bool get inProgress => const [
    'QUEUED',
    'SCRAPING',
    'GENERATING',
    'IMPORTING',
  ].contains(status);

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';

  List<String> get hostNameList => hostNames
      .split(',')
      .map((h) => h.trim())
      .where((h) => h.isNotEmpty)
      .toList();

  @override
  String toString() =>
      'WebsiteConversion $conversionId $sourceUrl $status ($companyName)';
}
