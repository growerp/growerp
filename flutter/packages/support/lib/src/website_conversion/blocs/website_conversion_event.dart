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

abstract class WebsiteConversionEvent extends Equatable {
  const WebsiteConversionEvent();
  @override
  List<Object> get props => [];
}

class WebsiteConversionFetch extends WebsiteConversionEvent {
  const WebsiteConversionFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
    this.background = false,
  });

  final String searchString;
  final bool refresh;
  final int limit;

  /// a poll while a conversion is running: must not disturb an open dialog
  final bool background;

  @override
  List<Object> get props => [searchString, refresh, background];
}

/// fetch one conversion, the only call that returns the generated password
class WebsiteConversionGetOne extends WebsiteConversionEvent {
  const WebsiteConversionGetOne(this.conversionId);
  final String conversionId;
  @override
  List<Object> get props => [conversionId];
}

class WebsiteConversionCreate extends WebsiteConversionEvent {
  const WebsiteConversionCreate({
    required this.sourceUrl,
    required this.companyName,
    required this.adminEmail,
    this.adminFirstName,
    this.adminLastName,
    required this.currencyId,
    this.applicationId,
    this.hostNames,
    this.maxPages,
  });

  final String sourceUrl;
  final String companyName;
  final String adminEmail;
  final String? adminFirstName;
  final String? adminLastName;
  final String currencyId;
  final String? applicationId;
  final String? hostNames;
  final int? maxPages;

  @override
  List<Object> get props => [sourceUrl, companyName, adminEmail];
}

class WebsiteConversionDelete extends WebsiteConversionEvent {
  const WebsiteConversionDelete(this.conversion);
  final WebsiteConversion conversion;
  @override
  List<Object> get props => [conversion.conversionId];
}

/// rebuild the owner-import XML of a finished website and hand it back for saving
class WebsiteConversionExport extends WebsiteConversionEvent {
  const WebsiteConversionExport(this.conversion);
  final WebsiteConversion conversion;
  @override
  List<Object> get props => [conversion.conversionId];
}

/// install an owner-import XML file picked from disk
class WebsiteConversionImportFile extends WebsiteConversionEvent {
  const WebsiteConversionImportFile(this.xmlText, this.fileName);
  final String xmlText;
  final String fileName;
  @override
  List<Object> get props => [fileName];
}
