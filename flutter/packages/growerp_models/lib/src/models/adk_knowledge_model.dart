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
import 'assessment_model.dart' show NullableTimestampConverter;

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
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Full document text — returned only by the detail endpoint (joined chunks).
  final String? content;

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
    this.content,
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
