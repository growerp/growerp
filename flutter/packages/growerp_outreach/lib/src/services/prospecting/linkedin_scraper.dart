import 'package:flutter/foundation.dart';

import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';
import 'prospect_query.dart';
import 'prospect_scrape_result.dart';
import 'prospect_scraper.dart';

/// LinkedIn people-search scraper.
///
/// Uses Browser MCP (Playwright) to automate LinkedIn's people-search UI.
/// Requires the user to already be authenticated in the browser session.
///
/// Supported [ProspectQuery] fields:
///  - [ProspectQuery.keywords]  → search box
///  - [ProspectQuery.title]     → "Title" filter
///  - [ProspectQuery.location]  → "Location" filter
///  - [ProspectQuery.companyName] → "Current company" filter
///  - [ProspectQuery.maxResults] → pagination stop
///
/// The scraper applies filters via the LinkedIn "All Filters" modal when
/// structured fields are provided, otherwise falls back to a plain keywords
/// search.
class LinkedInScraper implements ProspectScraper {
  LinkedInScraper({FlutterMcpBrowserService? browser})
    : _browser = browser ?? FlutterMcpBrowserService();

  final FlutterMcpBrowserService _browser;
  bool _initialized = false;

  // LinkedIn URL patterns
  static const _baseSearchUrl =
      'https://www.linkedin.com/search/results/people/';

  @override
  String get sourceName => 'linkedin';

  @override
  String get description =>
      'LinkedIn people-search scraper — finds profiles by keywords, title, '
      'company and location using the LinkedIn search UI.';

  @override
  bool canHandle(ProspectQuery query) {
    final hint = query.sourceHint?.toLowerCase();
    if (hint == null) return true; // participate in all-scraper runs
    return hint == 'linkedin';
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _browser.initialize();
    await _browser.navigate('https://www.linkedin.com');
    _initialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) return false;
    try {
      final snap = await _browser.snapshot();
      return SnapshotParser.findByText(snap, 'Home') != null ||
          SnapshotParser.findByText(snap, 'Messaging') != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ProspectScrapeResult>> scrape(ProspectQuery query) async {
    final results = <ProspectScrapeResult>[];

    // Build search URL with available parameters
    final urlQueryParams = <String, String>{'keywords': query.toSearchString()};
    if (query.title != null) {
      // LinkedIn encodes job-title filters differently per session,
      // so we embed it in keywords as a fallback.
      urlQueryParams['keywords'] = '${query.keywords} ${query.title}';
    }

    final searchUrl =
        '$_baseSearchUrl?'
        '${urlQueryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    await _browser.navigate(searchUrl);
    await _browser.wait(3000);

    // Apply structured filters via the "All Filters" modal if available
    if (query.location != null || query.companyName != null) {
      await _applyFilters(query);
    }

    // Paginate through results
    int page = 1;
    while (results.length < query.maxResults) {
      final snap = await _browser.snapshot();
      final pageResults = _parseSearchResultPage(snap);

      if (pageResults.isEmpty) break;
      results.addAll(pageResults);

      debugPrint(
        '[LinkedInScraper] Page $page: ${pageResults.length} profiles '
        '(total ${results.length})',
      );

      if (results.length >= query.maxResults) break;

      // Try to click the "Next" pagination button
      final nextBtn = SnapshotParser.findFirst(
        snap,
        role: 'button',
        predicate: (e) =>
            (e.name ?? '').toLowerCase().contains('next') ||
            (e.getAttribute('aria-label') ?? '').toLowerCase() == 'next',
      );

      if (nextBtn == null) break;

      try {
        await _browser.clickElement(nextBtn);
        await _browser.wait(3000);
        page++;
      } catch (e) {
        debugPrint('[LinkedInScraper] Pagination error: $e');
        break;
      }
    }

    return results.take(query.maxResults).toList();
  }

  @override
  Future<void> cleanup() async {
    _initialized = false;
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Apply location / company filters via the "All Filters" modal.
  Future<void> _applyFilters(ProspectQuery query) async {
    final snap = await _browser.snapshot();

    // Find the "All filters" button
    final allFiltersBtn = SnapshotParser.findFirst(
      snap,
      role: 'button',
      predicate: (e) => (e.name ?? '').toLowerCase().contains('all filter'),
    );

    if (allFiltersBtn == null) {
      debugPrint('[LinkedInScraper] "All filters" button not found, skipping');
      return;
    }

    await _browser.clickElement(allFiltersBtn);
    await _browser.wait(1500);

    final filterSnap = await _browser.snapshot();

    // Location filter
    if (query.location != null) {
      await _fillFilterInput(
        filterSnap,
        labelHint: 'location',
        value: query.location!,
      );
      await _browser.wait(1000);
    }

    // Current company filter
    if (query.companyName != null) {
      await _fillFilterInput(
        filterSnap,
        labelHint: 'company',
        value: query.companyName!,
      );
      await _browser.wait(1000);
    }

    // Submit modal
    final applyBtn = SnapshotParser.findFirst(
      filterSnap,
      role: 'button',
      predicate: (e) => (e.name ?? '').toLowerCase().contains('apply'),
    );

    if (applyBtn != null) {
      await _browser.clickElement(applyBtn);
      await _browser.wait(3000);
    }
  }

  Future<void> _fillFilterInput(
    SnapshotElement snap, {
    required String labelHint,
    required String value,
  }) async {
    final input = SnapshotParser.findFirst(
      snap,
      role: 'textbox',
      predicate: (e) =>
          (e.name ?? '').toLowerCase().contains(labelHint) ||
          (e.getAttribute('placeholder') ?? '').toLowerCase().contains(
            labelHint,
          ),
    );

    if (input == null) {
      debugPrint('[LinkedInScraper] Filter input "$labelHint" not found');
      return;
    }

    await _browser.typeIntoElement(input, value);
    await _browser.wait(800);

    // Choose the first autocomplete suggestion
    final updatedSnap = await _browser.snapshot();
    final suggestion = SnapshotParser.findFirst(updatedSnap, role: 'option');
    if (suggestion != null) {
      await _browser.clickElement(suggestion);
      await _browser.wait(500);
    }
  }

  /// Parse one page of LinkedIn people-search results from the snapshot.
  List<ProspectScrapeResult> _parseSearchResultPage(SnapshotElement snap) {
    final results = <ProspectScrapeResult>[];

    // Name links follow the pattern: role=link, href contains '/in/'
    final profileLinks = SnapshotParser.findAll(
      snap,
      role: 'link',
      predicate: (e) {
        final href = e.getAttribute('href') ?? e.value ?? '';
        return href.contains('/in/');
      },
    );

    final seen = <String>{};

    for (final link in profileLinks) {
      final href = link.getAttribute('href') ?? link.value ?? '';
      final inMatch = RegExp(r'/in/([a-zA-Z0-9\-_%]+)').firstMatch(href);
      if (inMatch == null) continue;

      final slug = inMatch.group(1)!;
      if (seen.contains(slug)) continue;
      seen.add(slug);

      final profileUrl = 'https://www.linkedin.com/in/$slug';
      final name = link.name?.trim();
      if (name == null || name.isEmpty) continue;

      // Try to find title & company in sibling text nodes
      final (title, company, location, degree) = _extractCardContext(
        snap,
        name,
      );

      results.add(
        ProspectScrapeResult(
          name: name,
          source: sourceName,
          sourceId: slug,
          profileUrl: profileUrl,
          handle: slug,
          title: title,
          company: company,
          location: location,
          connectionDegree: degree,
          confidence: 0.85,
          scrapedAt: DateTime.now().toUtc(),
          rawData: {'slug': slug},
        ),
      );
    }

    return results;
  }

  /// Heuristic: scan the accessibility tree around the profile name for
  /// subordinate text that looks like a title/company/location line.
  ///
  /// LinkedIn result cards typically render:
  ///   `<Name>`
  ///   `<Title at Company>`
  ///   `<Location>`
  ///   • 2nd+ (connection degree)
  (String?, String?, String?, int?) _extractCardContext(
    SnapshotElement snap,
    String name,
  ) {
    String? title;
    String? company;
    String? location;
    int? degree;

    // Find the name element then look at its nearest siblings
    bool foundName = false;
    void visit(SnapshotElement e) {
      if (foundName) return;
      if ((e.name ?? '').trim() == name) {
        foundName = true;
      }
    }

    // Quick walk: collect all text nodes in document order
    final texts = <String>[];
    void collect(SnapshotElement e) {
      if (e.name != null && e.name!.trim().isNotEmpty) {
        texts.add(e.name!.trim());
      }
      for (final c in e.children) {
        collect(c);
      }
    }

    collect(snap);
    visit(snap);

    final nameIdx = texts.indexOf(name);
    if (nameIdx >= 0) {
      // The 1-3 items immediately after the name are usually:
      // subtitle (title at company), location, degree badge
      for (int i = nameIdx + 1; i < texts.length && i <= nameIdx + 4; i++) {
        final t = texts[i];
        if (t.contains(' at ') && title == null) {
          final parts = t.split(' at ');
          title = parts.first.trim();
          company = parts.last.trim();
        } else if (_looksLikeLocation(t) && location == null) {
          location = t;
        } else if (t.startsWith('1st')) {
          degree = 1;
        } else if (t.startsWith('2nd')) {
          degree = 2;
        } else if (t.startsWith('3rd') || t.contains('3rd+')) {
          degree = 3;
        }
      }
    }

    return (title, company, location, degree);
  }

  bool _looksLikeLocation(String s) {
    // Heuristic: locations contain a comma or known region keywords
    if (s.contains(',')) return true;
    final lower = s.toLowerCase();
    return lower.contains('area') ||
        lower.contains('region') ||
        lower.contains('metro') ||
        lower.contains(' ca') ||
        lower.contains(' ny') ||
        lower.contains(' tx');
  }
}
