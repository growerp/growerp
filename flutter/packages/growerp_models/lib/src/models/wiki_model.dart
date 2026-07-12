/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
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
