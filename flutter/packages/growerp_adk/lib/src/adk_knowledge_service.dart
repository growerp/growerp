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

import 'dart:convert';

import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

/// Tenant-scoped REST wrapper for the agent knowledge base (Phase 3 RAG).
class AdkKnowledgeService {
  final RestClient _client;

  AdkKnowledgeService._(this._client);

  static Future<AdkKnowledgeService> create() async {
    final client = RestClient(await buildDioClient());
    return AdkKnowledgeService._(client);
  }

  Future<List<AdkKnowledgeDoc>> list({String? search}) async {
    final result = await _client.getAdkKnowledge(search: search);
    return result.adkKnowledgeDocs;
  }

  /// Full document (with joined chunk text) for the detail view.
  Future<AdkKnowledgeDoc> detail(String adkKnowledgeDocId) async =>
      _client.getAdkKnowledgeDetail(adkKnowledgeDocId: adkKnowledgeDocId);

  Future<AdkKnowledgeDoc> add(String title, String text,
          {String sourceType = 'note'}) async =>
      _client.createAdkKnowledge(
          title: title, text: text, sourceType: sourceType);

  Future<void> update(String adkKnowledgeDocId,
          {String? title, String? text}) async =>
      _client.updateAdkKnowledge(
          adkKnowledgeDocId: adkKnowledgeDocId, title: title, text: text);

  Future<void> delete(String adkKnowledgeDocId) async =>
      _client.deleteAdkKnowledge(adkKnowledgeDocId: adkKnowledgeDocId);

  /// Auto-ingest the company's product catalog into the knowledge base.
  /// Returns the number of products processed. The endpoint may hand back the
  /// body as a Map (decoded) or a raw JSON String depending on content-type, so
  /// decode defensively.
  Future<int> importProducts() async {
    dynamic data = await _client.importAdkKnowledgeProducts();
    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return 0;
      try {
        data = jsonDecode(s);
      } catch (_) {
        return int.tryParse(s) ?? 0;
      }
    }
    if (data is Map) {
      final n = data['productCount'];
      return n is int ? n : int.tryParse('$n') ?? 0;
    }
    return 0;
  }
}
