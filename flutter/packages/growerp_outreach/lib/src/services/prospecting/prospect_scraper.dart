import 'prospect_query.dart';
import 'prospect_scrape_result.dart';

/// Contract that every platform-specific prospect scraper must fulfil.
///
/// Each implementation targets one data source (LinkedIn, Apollo, a generic
/// webpage, etc.) and is responsible for:
///  1. Deciding whether it can handle a given [ProspectQuery].
///  2. Navigating / authenticating with that source.
///  3. Returning a list of [ProspectScrapeResult] records.
///
/// Scrapers are stateful (they hold a browser session) and must be
/// [initialize]d before [scrape] is called.  [cleanup] releases resources.
abstract class ProspectScraper {
  /// Short, machine-readable source identifier used in
  /// [ProspectScrapeResult.source], e.g. 'linkedin', 'apollo', 'generic'.
  String get sourceName;

  /// Human-readable description of what this scraper does.
  String get description;

  /// Returns true when this scraper believes it can satisfy [query].
  ///
  /// Implementations should check [ProspectQuery.sourceHint] first:
  ///   - If the hint matches [sourceName], return true.
  ///   - If the hint is set but doesn't match, return false.
  ///   - If the hint is null, return true if the scraper can run
  ///     unconditionally (always-on) or false if it needs an explicit hint.
  bool canHandle(ProspectQuery query);

  /// Initialise the underlying browser / HTTP client.
  ///
  /// Called once before [scrape].  Implementations should be idempotent
  /// (calling multiple times must not crash or double-initialise).
  Future<void> initialize();

  /// Check whether the scraper is authenticated / available.
  ///
  /// Returns false if the user needs to log in or the service is unreachable.
  Future<bool> isAvailable();

  /// Scrape [query] and return prospect records, up to [query.maxResults].
  ///
  /// Implementations should not throw on partial-result pages; they should
  /// return whatever results were collected and log the error internally.
  Future<List<ProspectScrapeResult>> scrape(ProspectQuery query);

  /// Release resources (close browser tab/page, etc.).
  ///
  /// The scraper must be re-[initialize]d before calling [scrape] again.
  Future<void> cleanup();
}
