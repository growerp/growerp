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

part 'website_export_model.freezed.dart';
part 'website_export_model.g.dart';

/// An owner-import XML document rebuilt from a live website, ready to be saved
/// to a file and installed on another GrowERP installation.
@freezed
abstract class WebsiteExport with _$WebsiteExport {
  factory WebsiteExport({
    @Default('') String xmlText,
    @Default('') String fileName,
    int? pageCount,
    int? imageCount,
  }) = _WebsiteExport;
  WebsiteExport._();

  factory WebsiteExport.fromJson(Map<String, dynamic> json) =>
      _$WebsiteExportFromJson(json['websiteExport'] ?? json);
}
