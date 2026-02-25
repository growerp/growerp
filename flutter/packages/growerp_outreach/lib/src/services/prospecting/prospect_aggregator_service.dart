import 'package:flutter/foundation.dart';

import 'prospect_query.dart';
import 'prospect_scrape_result.dart';
import 'prospect_scraper.dart';
import 'generic_web_scraper.dart';
import 'linkedin_scraper.dart';
import 'apollo_scraper.dart';

/// Dispatches a [ProspectQuery] to one or more registered [ProspectScraper]s,
/// merges and deduplicates the results, then returns a single ranked list.
///
/// ## Default registry
/// Three scrapers are registered out of the box (in priority order):
///   1. [ApolloScraper]      — richest data, email-first
///   2. [LinkedInScraper]    — largest network coverage
///   3. [GenericWebScraper]  — fallback for any URL or Google search
///
/// You can override the registry by passing a custom [scrapers] list to the
/// constructor, or add to it with [registerScraper].
///
/// ## Routing
/// If [ProspectQuery.sourceHint] is set, only scrapers that return `true`
/// from [ProspectScraper.canHandle] are invoked.  When the hint is null,
/// every registered scraper is tried (with errors caught individually).
///
/// ## Deduplication
/// Records are deduplicated by [ProspectScrapeResult.dedupeKey] after merging.
/// When two scrapers return the same contact the record with the higher
/// [ProspectScrapeResult.confidence] is kept; missing fields are filled from
/// the secondary record.
///
/// ## Pagination
/// [ProspectQuery.maxResults] is enforced globally after merge & dedup.
class ProspectAggregatorService {
  ProspectAggregatorService({
    List<ProspectScraper>? scrapers,
    this.parallelScraping = false,
  }) : _scrapers =
           scrapers ??
           [ApolloScraper(), LinkedInScraper(), GenericWebScraper()];

  final List<ProspectScraper> _scrapers;

  /// When true, all eligible scrapers run concurrently via [Future.wait].
  /// When false (default), they run sequentially and stop early once
  /// [ProspectQuery.maxResults] is reached.
  final bool parallelScraping;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Add a scraper to the front of the priority list.
  void registerScraper(ProspectScraper scraper) {
    _scrapers.insert(0, scraper);
  }

  /// Initialise all registered scrapers.
  ///
  /// Call once before the first [scrape].  Individual failures are logged
  /// but do not throw.
  Future<void> initialize() async {
    for (final scraper in _scrapers) {
      try {
        await scraper.initialize();
      } catch (e) {
        debugPrint(
          '[ProspectAggregator] Init failed for ${scraper.sourceName}: $e',
        );
      }
    }
  }

  /// Scrape [query] across all eligible scrapers and return a unified,
  /// deduplicated list of up to [ProspectQuery.maxResults] prospects.
  Future<List<ProspectScrapeResult>> scrape(ProspectQuery query) async {
    final eligible = _scrapers
        .where((s) => s.canHandle(query))
        .toList(growable: false);

    if (eligible.isEmpty) {
      debugPrint('[ProspectAggregator] No eligible scrapers for: $query');
      return [];
    }

    debugPrint(
      '[ProspectAggregator] Scraping with ${eligible.length} scrapers '
      'for: $query',
    );

    final rawResults = <ProspectScrapeResult>[];

    if (parallelScraping) {
      final futures = eligible.map((s) => _safeScrape(s, query));
      final batches = await Future.wait(futures);
      for (final batch in batches) {
        rawResults.addAll(batch);
      }
    } else {
      for (final scraper in eligible) {
        if (rawResults.length >= query.maxResults) break;

        // Pass a reduced maxResults to avoid over-fetching
        final remaining = query.maxResults - rawResults.length;
        final reducedQuery = ProspectQuery(
          keywords: query.keywords,
          location: query.location,
          industry: query.industry,
          title: query.title,
          companyName: query.companyName,
          maxResults: remaining,
          sourceHint: query.sourceHint,
          extraFilters: query.extraFilters,
        );

        final batch = await _safeScrape(scraper, reducedQuery);
        rawResults.addAll(batch);
        debugPrint(
          '[ProspectAggregator] ${scraper.sourceName}: +${batch.length} '
          '(running total ${rawResults.length})',
        );
      }
    }

    final merged = _deduplicateAndMerge(rawResults);
    final sorted = _rank(merged, query);
    final final_ = sorted.take(query.maxResults).toList();

    debugPrint(
      '[ProspectAggregator] Final: ${final_.length} prospects '
      '(from ${rawResults.length} raw)',
    );

    return final_;
  }

  /// Release all scraper resources.
  Future<void> cleanup() async {
    for (final scraper in _scrapers) {
      try {
        await scraper.cleanup();
      } catch (_) {}
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Wrap a scraper call so errors don't abort the whole run.
  Future<List<ProspectScrapeResult>> _safeScrape(
    ProspectScraper scraper,
    ProspectQuery query,
  ) async {
    try {
      final available = await scraper.isAvailable();
      if (!available) {
        debugPrint(
          '[ProspectAggregator] ${scraper.sourceName} not available, skipping',
        );
        return [];
      }
      return await scraper.scrape(query);
    } catch (e, st) {
      debugPrint('[ProspectAggregator] ${scraper.sourceName} error: $e\n$st');
      return [];
    }
  }

  /// Deduplicate by [ProspectScrapeResult.dedupeKey] and merge fields from
  /// secondary records into primary records.
  List<ProspectScrapeResult> _deduplicateAndMerge(
    List<ProspectScrapeResult> results,
  ) {
    final byKey = <String, ProspectScrapeResult>{};

    for (final r in results) {
      final key = r.dedupeKey;
      final existing = byKey[key];

      if (existing == null) {
        byKey[key] = r;
      } else {
        byKey[key] = _mergeRecords(existing, r);
      }
    }

    return byKey.values.toList();
  }

  /// Merge two records for the same identity.
  ///
  /// The record with the higher confidence is the "primary"; fields missing in
  /// primary are filled from secondary.
  ProspectScrapeResult _mergeRecords(
    ProspectScrapeResult a,
    ProspectScrapeResult b,
  ) {
    final primary = a.confidence >= b.confidence ? a : b;
    final secondary = a.confidence >= b.confidence ? b : a;

    // Boost confidence slightly when the same person was corroborated by
    // a second independent source (cap at 1.0)
    final boosted = (primary.confidence + 0.05).clamp(0.0, 1.0);

    // Source string lists both origins
    final mergedSource = primary.source == secondary.source
        ? primary.source
        : '${primary.source}+${secondary.source}';

    return primary.copyWith(
      source: mergedSource,
      email: primary.email ?? secondary.email,
      phone: primary.phone ?? secondary.phone,
      title: primary.title ?? secondary.title,
      company: primary.company ?? secondary.company,
      location: primary.location ?? secondary.location,
      industry: primary.industry ?? secondary.industry,
      handle: primary.handle ?? secondary.handle,
      profileUrl: primary.profileUrl ?? secondary.profileUrl,
      connectionDegree: primary.connectionDegree ?? secondary.connectionDegree,
      confidence: boosted,
      tags: {...primary.tags, ...secondary.tags}.toList(),
    );
  }

  /// Sort by confidence descending, with email-bearing records first.
  List<ProspectScrapeResult> _rank(
    List<ProspectScrapeResult> results,
    ProspectQuery query,
  ) {
    return results..sort((a, b) {
      // Email-bearing records rank highest
      final aHasEmail = (a.email != null) ? 1 : 0;
      final bHasEmail = (b.email != null) ? 1 : 0;
      if (aHasEmail != bHasEmail) return bHasEmail - aHasEmail;

      // Then by confidence descending
      return b.confidence.compareTo(a.confidence);
    });
  }
}
