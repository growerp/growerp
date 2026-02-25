import 'package:flutter/foundation.dart';

import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';
import 'prospect_query.dart';
import 'prospect_scrape_result.dart';
import 'prospect_scraper.dart';

/// General-purpose web scraper that works on any publicly accessible URL.
///
/// Strategy:
///  1. If [ProspectQuery.sourceHint] starts with 'http', navigate directly to
///     that URL and mine the page for contact signals.
///  2. Otherwise, run a Google search for the keywords and mine the result page
///     for LinkedIn profile links, plain email addresses and named entities.
///
/// This scraper is the last resort — specialised scrapers like
/// [LinkedInScraper] and [ApolloScraper] should be preferred when the source
/// is known.
class GenericWebScraper implements ProspectScraper {
  GenericWebScraper({FlutterMcpBrowserService? browser})
    : _browser = browser ?? FlutterMcpBrowserService();

  final FlutterMcpBrowserService _browser;
  bool _initialized = false;

  // Regex patterns for contact extraction from raw page text
  static final _emailRe = RegExp(
    r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
  );
  static final _linkedinRe = RegExp(
    r'https?://(?:www\.)?linkedin\.com/in/([a-zA-Z0-9\-_%]+)',
  );
  static final _phoneRe = RegExp(
    r'(?:\+?1[\s\-.]?)?\(?\d{3}\)?[\s\-.]?\d{3}[\s\-.]?\d{4}',
  );

  @override
  String get sourceName => 'generic';

  @override
  String get description =>
      'General web scraper — Google search or direct URL, '
      'extracts emails, LinkedIn links and named entities from page content.';

  @override
  bool canHandle(ProspectQuery query) {
    final hint = query.sourceHint?.toLowerCase();
    if (hint == null) return true; // always act as fallback
    return hint == 'generic' || hint.startsWith('http');
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _browser.initialize();
    _initialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) return false;
    try {
      await _browser.navigate('https://www.google.com');
      await _browser.wait(1500);
      final snap = await _browser.snapshot();
      return SnapshotParser.findByText(snap, 'Google') != null ||
          SnapshotParser.findByText(snap, 'Search') != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ProspectScrapeResult>> scrape(ProspectQuery query) async {
    final hint = query.sourceHint ?? '';
    if (hint.startsWith('http')) {
      return _scrapeUrl(hint, query);
    }
    return _googleSearch(query);
  }

  @override
  Future<void> cleanup() async {
    _initialized = false;
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Navigate to a direct URL and harvest contact data from the page.
  Future<List<ProspectScrapeResult>> _scrapeUrl(
    String url,
    ProspectQuery query,
  ) async {
    await _browser.navigate(url);
    await _browser.wait(2500);
    final snap = await _browser.snapshot();
    return _extractFromSnapshot(snap, sourceUrl: url, query: query);
  }

  /// Run a Google search and harvest contact links from the SERP.
  Future<List<ProspectScrapeResult>> _googleSearch(ProspectQuery query) async {
    final q = Uri.encodeComponent(query.toSearchString());
    await _browser.navigate('https://www.google.com/search?q=$q&num=30');
    await _browser.wait(2500);
    final snap = await _browser.snapshot();

    final results = <ProspectScrapeResult>[];

    // 1. LinkedIn profile links in SERP
    final linkedinLinks = SnapshotParser.findAll(
      snap,
      role: 'link',
      predicate: (e) {
        final href = e.getAttribute('href') ?? e.value ?? '';
        return _linkedinRe.hasMatch(href);
      },
    );

    for (final link in linkedinLinks) {
      final href = link.getAttribute('href') ?? link.value ?? '';
      final match = _linkedinRe.firstMatch(href);
      if (match == null) continue;
      final slug = match.group(1)!;
      final name = _titleCaseSlug(slug);
      results.add(
        ProspectScrapeResult(
          name: name,
          source: sourceName,
          profileUrl: 'https://www.linkedin.com/in/$slug',
          handle: slug,
          confidence: 0.6, // discovered via SERP, not yet verified
          scrapedAt: DateTime.now().toUtc(),
          rawData: {'serpLinkText': link.name ?? ''},
        ),
      );
      if (results.length >= query.maxResults) break;
    }

    // 2. Email addresses visible in SERP snippets
    if (results.length < query.maxResults) {
      final emailProspects = _extractEmailsFromSnapshot(
        snap,
        sourceUrl: 'google-search:$q',
      );
      for (final p in emailProspects) {
        if (results.length >= query.maxResults) break;
        results.add(p);
      }
    }

    debugPrint(
      '[GenericWebScraper] Google search found ${results.length} prospects',
    );
    return results;
  }

  /// Walk the accessibility tree and extract every contact signal available.
  List<ProspectScrapeResult> _extractFromSnapshot(
    SnapshotElement snap, {
    required String sourceUrl,
    required ProspectQuery query,
  }) {
    final results = <ProspectScrapeResult>[];

    // Collect all visible text in DFS order
    final allText = _collectText(snap);

    // Extract unique emails
    final emails = _emailRe.allMatches(allText).map((m) => m.group(0)!).toSet();
    for (final email in emails) {
      if (results.length >= query.maxResults) break;
      // Associate a phone if one appears within 100 chars of this email
      final emailIdx = allText.indexOf(email);
      String? phone;
      if (emailIdx >= 0) {
        final window = allText.substring(
          (emailIdx - 100).clamp(0, allText.length),
          (emailIdx + 100).clamp(0, allText.length),
        );
        phone = _phoneRe.firstMatch(window)?.group(0);
      }
      results.add(
        ProspectScrapeResult(
          name: email.split('@').first,
          source: '$sourceName:$sourceUrl',
          email: email,
          phone: phone,
          confidence: 0.7,
          scrapedAt: DateTime.now().toUtc(),
          rawData: {'extractedFrom': sourceUrl},
        ),
      );
    }

    // Extract LinkedIn profiles embedded in this non-LinkedIn page
    final liMatches = _linkedinRe.allMatches(allText);
    for (final m in liMatches) {
      if (results.length >= query.maxResults) break;
      final slug = m.group(1)!;
      // Avoid duplicating if we already have by email
      final url = 'https://www.linkedin.com/in/$slug';
      if (results.any((r) => r.profileUrl == url)) continue;
      results.add(
        ProspectScrapeResult(
          name: _titleCaseSlug(slug),
          source: '$sourceName:$sourceUrl',
          profileUrl: url,
          handle: slug,
          confidence: 0.55,
          scrapedAt: DateTime.now().toUtc(),
        ),
      );
    }

    debugPrint(
      '[GenericWebScraper] Extracted ${results.length} prospects from $sourceUrl',
    );
    return results;
  }

  List<ProspectScrapeResult> _extractEmailsFromSnapshot(
    SnapshotElement snap, {
    required String sourceUrl,
  }) {
    final text = _collectText(snap);
    return _emailRe
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toSet()
        .map(
          (email) => ProspectScrapeResult(
            name: email.split('@').first,
            source: '$sourceName:$sourceUrl',
            email: email,
            confidence: 0.6,
            scrapedAt: DateTime.now().toUtc(),
          ),
        )
        .toList();
  }

  /// DFS collect all visible text in the snapshot tree.
  String _collectText(SnapshotElement root) {
    final buf = StringBuffer();
    void visit(SnapshotElement e) {
      if (e.name != null) buf.write('${e.name} ');
      if (e.value != null) buf.write('${e.value} ');
      for (final child in e.children) {
        visit(child);
      }
    }

    visit(root);
    return buf.toString();
  }

  /// Convert a LinkedIn vanity slug like 'john-doe-42ab' into 'John Doe 42ab'.
  String _titleCaseSlug(String slug) {
    return slug
        .split('-')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ')
        .trim();
  }
}
