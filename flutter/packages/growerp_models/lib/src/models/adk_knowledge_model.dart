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

/// Knowledge base statistics: size, recency, index health and search usage.
@JsonSerializable(explicitToJson: true)
class AdkKnowledgeStats {
  final int docCount;
  final int chunkCount;

  /// Estimated (~4 characters a token).
  final int tokenCount;
  final int docsAddedLast30Days;
  @NullableTimestampConverter()
  final DateTime? lastChangedDate;
  final List<AdkKnowledgeTypeCount> bySourceType;

  /// Folders of ZIP loaded documents, most documents first (top 10).
  final List<AdkKnowledgeFolderCount> topFolders;

  /// Null when no embedding key is configured.
  final String? currentEmbeddingModel;

  /// Chunks embedded with another model than the current one: search skips them.
  final int staleChunkCount;
  final int staleDocCount;

  /// Documents without any chunk: never found by search.
  final int emptyDocCount;
  final int searchCountLast30Days;
  final int emptySearchCountLast30Days;
  @NullableTimestampConverter()
  final DateTime? lastSearchDate;

  const AdkKnowledgeStats({
    this.docCount = 0,
    this.chunkCount = 0,
    this.tokenCount = 0,
    this.docsAddedLast30Days = 0,
    this.lastChangedDate,
    this.bySourceType = const [],
    this.topFolders = const [],
    this.currentEmbeddingModel,
    this.staleChunkCount = 0,
    this.staleDocCount = 0,
    this.emptyDocCount = 0,
    this.searchCountLast30Days = 0,
    this.emptySearchCountLast30Days = 0,
    this.lastSearchDate,
  });

  factory AdkKnowledgeStats.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AdkKnowledgeStatsToJson(this);
}

@JsonSerializable()
class AdkKnowledgeTypeCount {
  final String sourceType;
  final int docCount;
  final int chunkCount;

  const AdkKnowledgeTypeCount({
    this.sourceType = 'other',
    this.docCount = 0,
    this.chunkCount = 0,
  });

  factory AdkKnowledgeTypeCount.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeTypeCountFromJson(json);
  Map<String, dynamic> toJson() => _$AdkKnowledgeTypeCountToJson(this);
}

@JsonSerializable()
class AdkKnowledgeFolderCount {
  final String folder;
  final int docCount;

  const AdkKnowledgeFolderCount({this.folder = '', this.docCount = 0});

  factory AdkKnowledgeFolderCount.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeFolderCountFromJson(json);
  Map<String, dynamic> toJson() => _$AdkKnowledgeFolderCountToJson(this);
}

/// A background knowledge load (ZIP upload or re-index) and its progress.
@JsonSerializable(explicitToJson: true)
class AdkKnowledgeImport {
  final String? adkKnowledgeImportId;

  /// ZIP | REINDEX
  final String? jobType;
  final String? fileName;

  /// QUEUED | RUNNING | DONE | ERROR
  final String? status;
  final int fileCount;
  final int processedCount;
  final int createdCount;
  final int updatedCount;
  final int skippedCount;
  final List<AdkKnowledgeSkipped> skipped;
  final String? errorMessage;
  @NullableTimestampConverter()
  final DateTime? createdDate;
  @NullableTimestampConverter()
  final DateTime? completedDate;

  const AdkKnowledgeImport({
    this.adkKnowledgeImportId,
    this.jobType,
    this.fileName,
    this.status,
    this.fileCount = 0,
    this.processedCount = 0,
    this.createdCount = 0,
    this.updatedCount = 0,
    this.skippedCount = 0,
    this.skipped = const [],
    this.errorMessage,
    this.createdDate,
    this.completedDate,
  });

  bool get isRunning => status == 'QUEUED' || status == 'RUNNING';

  /// Accepts the REST wrapper `{adkKnowledgeImport: {...}}` or the bare object.
  factory AdkKnowledgeImport.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeImportFromJson(
        json['adkKnowledgeImport'] is Map<String, dynamic>
            ? json['adkKnowledgeImport'] as Map<String, dynamic>
            : json,
      );
  Map<String, dynamic> toJson() => _$AdkKnowledgeImportToJson(this);
}

@JsonSerializable()
class AdkKnowledgeSkipped {
  final String path;
  final String reason;

  const AdkKnowledgeSkipped({this.path = '', this.reason = ''});

  factory AdkKnowledgeSkipped.fromJson(Map<String, dynamic> json) =>
      _$AdkKnowledgeSkippedFromJson(json);
  Map<String, dynamic> toJson() => _$AdkKnowledgeSkippedToJson(this);
}
