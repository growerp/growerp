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
  /// Returns the number of products processed.
  Future<int> importProducts() async {
    final result = await _client.importAdkKnowledgeProducts();
    final n = result['productCount'];
    return n is int ? n : int.tryParse('$n') ?? 0;
  }
}
