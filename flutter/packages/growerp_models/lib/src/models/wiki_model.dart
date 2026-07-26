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

import 'package:json_annotation/json_annotation.dart';

part 'wiki_model.g.dart';

/// A wiki space: a tree of markdown pages, e.g. the GROWERP_OKF knowledge bundle.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WikiSpace {
  final String? wikiSpaceId;
  final String? description;
  final String? rootPageLocation;
  final String? publicPageUrl;

  const WikiSpace({
    this.wikiSpaceId,
    this.description,
    this.rootPageLocation,
    this.publicPageUrl,
  });

  factory WikiSpace.fromJson(Map<String, dynamic> json) =>
      _$WikiSpaceFromJson(json);
  Map<String, dynamic> toJson() => _$WikiSpaceToJson(this);

  @override
  String toString() => 'WikiSpace[$wikiSpaceId]';
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WikiSpaces {
  final List<WikiSpace> wikiSpaces;

  const WikiSpaces({this.wikiSpaces = const []});

  factory WikiSpaces.fromJson(Map<String, dynamic> json) =>
      _$WikiSpacesFromJson(json);
  Map<String, dynamic> toJson() => _$WikiSpacesToJson(this);
}

/// One page of a wiki space; [pageText] is only returned by the detail endpoint.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WikiPage {
  final String? wikiPageId;
  final String? wikiSpaceId;
  final String? pagePath;
  final String? publishedVersionName;
  final String? pageText;

  const WikiPage({
    this.wikiPageId,
    this.wikiSpaceId,
    this.pagePath,
    this.publishedVersionName,
    this.pageText,
  });

  factory WikiPage.fromJson(Map<String, dynamic> json) =>
      _$WikiPageFromJson(
          json['wikiPage'] != null ? json['wikiPage'] as Map<String, dynamic> : json);
  Map<String, dynamic> toJson() => _$WikiPageToJson(this);

  @override
  String toString() => 'WikiPage[$wikiSpaceId/$pagePath]';
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WikiPages {
  final List<WikiPage> wikiPages;

  const WikiPages({this.wikiPages = const []});

  factory WikiPages.fromJson(Map<String, dynamic> json) =>
      _$WikiPagesFromJson(json);
  Map<String, dynamic> toJson() => _$WikiPagesToJson(this);
}
