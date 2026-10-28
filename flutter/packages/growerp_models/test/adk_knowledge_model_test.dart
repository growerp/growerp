import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

/// Knowledge statistics and background loads as the backend returns them.
void main() {
  test('statistics parse with nested counts and millisecond dates', () {
    final st = AdkKnowledgeStats.fromJson({
      'docCount': 3,
      'chunkCount': 5,
      'tokenCount': 1200,
      'docsAddedLast30Days': 2,
      'lastChangedDate': 1793613600000,
      'bySourceType': [
        {'sourceType': 'upload', 'docCount': 2, 'chunkCount': 4},
        {'sourceType': 'note', 'docCount': 1, 'chunkCount': 1},
      ],
      'topFolders': [
        {'folder': 'handbook/policies', 'docCount': 2},
      ],
      'currentEmbeddingModel': 'gemini-embedding-001',
      'staleChunkCount': 1,
      'staleDocCount': 1,
      'emptyDocCount': 0,
      'searchCountLast30Days': 7,
      'emptySearchCountLast30Days': 2,
    });
    expect(st.docCount, 3);
    expect(st.bySourceType.first.sourceType, 'upload');
    expect(st.bySourceType.first.chunkCount, 4);
    expect(st.topFolders.single.folder, 'handbook/policies');
    expect(
      st.lastChangedDate,
      DateTime.fromMillisecondsSinceEpoch(1793613600000),
    );
    expect(st.lastSearchDate, isNull);
    expect(st.staleDocCount, 1);
  });

  test('statistics of an empty knowledge base default to zero', () {
    final st = AdkKnowledgeStats.fromJson({
      'bySourceType': [],
      'topFolders': [],
    });
    expect(st.docCount, 0);
    expect(st.currentEmbeddingModel, isNull);
  });

  test('a load parses wrapped or bare, with skipped files', () {
    final bare = {
      'adkKnowledgeImportId': '100',
      'jobType': 'ZIP',
      'fileName': 'handbook.zip',
      'status': 'RUNNING',
      'fileCount': 4,
      'processedCount': 1,
      'skipped': [
        {'path': 'manuals/photo.png', 'reason': 'unsupported file type'},
      ],
    };
    for (final json in [
      bare,
      {'adkKnowledgeImport': bare},
    ]) {
      final job = AdkKnowledgeImport.fromJson(json);
      expect(job.adkKnowledgeImportId, '100');
      expect(job.isRunning, isTrue);
      expect(job.skipped.single.path, 'manuals/photo.png');
    }
  });

  test('a company without loads gets an empty load, not running', () {
    final job = AdkKnowledgeImport.fromJson({});
    expect(job.status, isNull);
    expect(job.isRunning, isFalse);
  });
}
