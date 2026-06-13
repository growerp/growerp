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

part 'adk_knowledge_model.g.dart';

/// A document/note in a company's agent knowledge base (Phase 3 RAG).
/// Tenant-scoped server-side.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AdkKnowledgeDoc {
  final String? adkKnowledgeDocId;
  final String? title;

  /// note | upload | product | policy | chat
  final String? sourceType;
  final String? mimeType;
  final int? chunkCount;
  final DateTime? createdDate;

  /// Write-only: the document text sent on create (chunked + embedded server-side).
  @JsonKey(includeFromJson: false)
  final String? text;

  const AdkKnowledgeDoc({
    this.adkKnowledgeDocId,
    this.title,
    this.sourceType,
    this.mimeType,
    this.chunkCount,
    this.createdDate,
    this.text,
  });

  factory AdkKnowledgeDoc.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeDocFromJson(json);
  Map<String, dynamic> toJson() => _$AdkKnowledgeDocToJson(this);

  @override
  String toString() =>
      'AdkKnowledgeDoc[$adkKnowledgeDocId: $title ($chunkCount chunks)]';
}

@JsonSerializable()
class AdkKnowledgeDocs {
  final List<AdkKnowledgeDoc> adkKnowledgeDocs;

  const AdkKnowledgeDocs({this.adkKnowledgeDocs = const []});

  factory AdkKnowledgeDocs.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeDocsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkKnowledgeDocsToJson(this);
}
