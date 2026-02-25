import 'package:flutter/foundation.dart';

import '../flutter_mcp_browser_service.dart';
import '../snapshot_parser.dart';
import 'prospect_query.dart';
import 'prospect_scrape_result.dart';
import 'prospect_scraper.dart';

/// Apollo.io people-search scraper.
///
/// Navigates `https://app.apollo.io/#/people`, fills in Apollo's structured
/// search filters (job title, company, location, keyword) and extracts the
/// results table.
///
/// Email reveal:
///   Apollo hides emails behind a "Reveal Email" button click that counts
///   against the user's monthly credit allowance.  By default this scraper
///   does NOT click reveal; set [revealEmails] = true to opt in.
///
/// Supported [ProspectQuery] fields:
///  - [ProspectQuery.keywords]    → person search box
///  - [ProspectQuery.title]       → "Job Title" multi-tag input
///  - [ProspectQuery.companyName] → "Company" multi-tag input
///  - [ProspectQuery.location]    → "Location" multi-tag input
///  - [ProspectQuery.industry]    → "Industry" multi-tag input (extraFilters key also works)
///  - [ProspectQuery.maxResults]  → row limit
///  - [ProspectQuery.extraFilters] relevant keys:
///      'seniorityLevel' → "Seniority" tag input (e.g. 'VP', 'Director')
///      'companySize'    → "# Employees" range preset text
class ApolloScraper implements ProspectScraper {
  ApolloScraper({FlutterMcpBrowserService? browser, this.revealEmails = false})
    : _browser = browser ?? FlutterMcpBrowserService();

  final FlutterMcpBrowserService _browser;
  final bool revealEmails;
  bool _initialized = false;

  static const _apolloPeopleUrl = 'https://app.apollo.io/#/people';

  @override
  String get sourceName => 'apollo';

  @override
  String get description =>
      'Apollo.io people-search scraper — uses Apollo\'s advanced filters '
      '(title, company, location, seniority, industry) to find B2B contacts.';

  @override
  bool canHandle(ProspectQuery query) {
    final hint = query.sourceHint?.toLowerCase();
    if (hint == null) return true;
    return hint == 'apollo' || hint == 'apollo.io';
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _browser.initialize();
    await _browser.navigate(_apolloPeopleUrl);
    await _browser.wait(3000);
    _initialized = true;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) return false;
    try {
      final snap = await _browser.snapshot();
      // Apollo shows "People" nav item when logged in
      return SnapshotParser.findByText(snap, 'People') != null ||
          SnapshotParser.findByText(snap, 'Contacts') != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ProspectScrapeResult>> scrape(ProspectQuery query) async {
    // Start fresh on the people page
    await _browser.navigate(_apolloPeopleUrl);
    await _browser.wait(3000);

    await _applyFilters(query);

    final results = <ProspectScrapeResult>[];
    int page = 1;

    while (results.length < query.maxResults) {
      final snap = await _browser.snapshot();
      final rows = _parseResultsTable(snap, revealEmails: revealEmails);

      if (rows.isEmpty) {
        debugPrint('[ApolloScraper] No rows on page $page, stopping');
        break;
      }

      results.addAll(rows);
      debugPrint(
        '[ApolloScraper] Page $page: ${rows.length} contacts '
        '(total ${results.length})',
      );

      if (results.length >= query.maxResults) break;

      // Try paginating
      final nextBtn = SnapshotParser.findFirst(
        snap,
        predicate: (e) =>
            (e.name ?? '').toLowerCase() == 'next' ||
            (e.getAttribute('aria-label') ?? '').toLowerCase() == 'next page',
      );

      if (nextBtn == null) break;

      try {
        await _browser.clickElement(nextBtn);
        await _browser.wait(3000);
        page++;
      } catch (e) {
        debugPrint('[ApolloScraper] Pagination error: $e');
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

  Future<void> _applyFilters(ProspectQuery query) async {
    // Job title
    if (query.title != null) {
      await _addTagFilter(hint: 'title', value: query.title!);
    }

    // Company name
    if (query.companyName != null) {
      await _addTagFilter(hint: 'company', value: query.companyName!);
    }

    // Location
    if (query.location != null) {
      await _addTagFilter(hint: 'location', value: query.location!);
    }

    // Industry (from query field or extraFilters)
    final industry = query.industry ?? query.extraFilters['industry'];
    if (industry != null) {
      await _addTagFilter(hint: 'industry', value: industry);
    }

    // Seniority from extraFilters
    final seniority = query.extraFilters['seniorityLevel'];
    if (seniority != null) {
      await _addTagFilter(hint: 'seniority', value: seniority);
    }

    // Full-text / person name keywords search box
    if (query.keywords.isNotEmpty) {
      final snap = await _browser.snapshot();
      final searchBox = SnapshotParser.findFirst(
        snap,
        role: 'textbox',
        predicate: (e) =>
            (e.name ?? '').toLowerCase().contains('search') ||
            (e.getAttribute('placeholder') ?? '').toLowerCase().contains(
              'name',
            ),
      );
      if (searchBox != null) {
        await _browser.typeIntoElement(searchBox, query.keywords, submit: true);
        await _browser.wait(2000);
      }
    }
  }

  /// Add a value to one of Apollo's multi-tag filter inputs.
  ///
  /// Apollo uses pill/tag inputs for most filters; the pattern is:
  ///   click the input → type value → wait for dropdown → click first option.
  Future<void> _addTagFilter({
    required String hint,
    required String value,
  }) async {
    final snap = await _browser.snapshot();

    // Find the filter section heading or input by hint text
    final input =
        SnapshotParser.findFirst(
          snap,
          role: 'textbox',
          predicate: (e) =>
              (e.name ?? '').toLowerCase().contains(hint) ||
              (e.getAttribute('placeholder') ?? '').toLowerCase().contains(
                hint,
              ),
        ) ??
        SnapshotParser.findFirst(
          snap,
          predicate: (e) => (e.getAttribute('data-test-id') ?? '')
              .toLowerCase()
              .contains(hint),
        );

    if (input == null) {
      debugPrint('[ApolloScraper] Filter input "$hint" not found');
      return;
    }

    await _browser.typeIntoElement(input, value);
    await _browser.wait(1200);

    // Select first suggestion
    final updatedSnap = await _browser.snapshot();
    final suggestion = SnapshotParser.findFirst(updatedSnap, role: 'option');
    if (suggestion != null) {
      await _browser.clickElement(suggestion);
      await _browser.wait(600);
    } else {
      // Fall back: press Enter to confirm as free-text tag
      await _browser.pressKey('Enter');
      await _browser.wait(600);
    }

    debugPrint('[ApolloScraper] Applied filter "$hint" = "$value"');
  }

  /// Parse Apollo's people table from the accessibility snapshot.
  ///
  /// Apollo renders a data-grid where each row contains:
  ///   - Person name (link to /contacts/:id)
  ///   - Job title
  ///   - Company name
  ///   - Location
  ///   - Email (either revealed or a "Reveal" button)
  ///   - Phone (similar)
  List<ProspectScrapeResult> _parseResultsTable(
    SnapshotElement snap, {
    required bool revealEmails,
  }) {
    final results = <ProspectScrapeResult>[];

    // Apollo contact row links follow the pattern /contacts/:id
    final contactLinks = SnapshotParser.findAll(
      snap,
      role: 'link',
      predicate: (e) {
        final href = e.getAttribute('href') ?? e.value ?? '';
        return href.contains('/contacts/');
      },
    );

    final seen = <String>{};

    for (final link in contactLinks) {
      final href = link.getAttribute('href') ?? link.value ?? '';
      final idMatch = RegExp(r'/contacts/([a-zA-Z0-9]+)').firstMatch(href);
      if (idMatch == null) continue;

      final contactId = idMatch.group(1)!;
      if (seen.contains(contactId)) continue;
      seen.add(contactId);

      final name = link.name?.trim();
      if (name == null || name.isEmpty) continue;

      final (title, company, location, email, apolloUrl) = _extractRowContext(
        snap,
        name,
        contactId,
      );

      results.add(
        ProspectScrapeResult(
          name: name,
          source: sourceName,
          sourceId: contactId,
          profileUrl: apolloUrl,
          email: email,
          title: title,
          company: company,
          location: location,
          confidence: email != null ? 0.95 : 0.75,
          scrapedAt: DateTime.now().toUtc(),
          rawData: {
            'apolloContactId': contactId,
            'emailRevealed': email != null,
          },
        ),
      );
    }

    return results;
  }

  /// Extract title / company / location / email from the flattened text
  /// nodes near the named contact.
  (String?, String?, String?, String?, String?) _extractRowContext(
    SnapshotElement snap,
    String name,
    String contactId,
  ) {
    // Collect all visible text in document order
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

    final nameIdx = texts.indexOf(name);
    String? title;
    String? company;
    String? location;
    String? email;
    final apolloUrl = 'https://app.apollo.io/#/contacts/$contactId';

    if (nameIdx >= 0) {
      final emailRe = RegExp(
        r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
      );

      for (int i = nameIdx + 1; i < texts.length && i <= nameIdx + 6; i++) {
        final t = texts[i];
        if (emailRe.hasMatch(t) && email == null) {
          email = emailRe.firstMatch(t)!.group(0);
        } else if (t.contains(' at ') && title == null) {
          final parts = t.split(' at ');
          title = parts.first.trim();
          company = parts.last.trim();
        } else if (title == null && _looksLikeTitle(t)) {
          title = t;
        } else if (company == null && _looksLikeCompany(t)) {
          company = t;
        } else if (location == null && t.contains(',')) {
          location = t;
        }
      }
    }

    return (title, company, location, email, apolloUrl);
  }

  bool _looksLikeTitle(String s) {
    final lower = s.toLowerCase();
    return lower.contains('engineer') ||
        lower.contains('manager') ||
        lower.contains('director') ||
        lower.contains('vp') ||
        lower.contains('head of') ||
        lower.contains('cto') ||
        lower.contains('ceo') ||
        lower.contains('founder') ||
        lower.contains('officer');
  }

  bool _looksLikeCompany(String s) {
    // Companies tend to be short and contain capitalised words
    return s.length < 60 && RegExp(r'^[A-Z]').hasMatch(s) && !s.contains('@');
  }
}
