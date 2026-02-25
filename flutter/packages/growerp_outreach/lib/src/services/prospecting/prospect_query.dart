/// Parameters that drive a prospecting search across one or more scrapers.
///
/// All fields are optional except [keywords]. Scrapers only use the fields
/// they support; unused fields are silently ignored.
class ProspectQuery {
  const ProspectQuery({
    required this.keywords,
    this.location,
    this.industry,
    this.title,
    this.companyName,
    this.maxResults = 50,
    this.sourceHint,
    this.extraFilters = const {},
  });

  /// Free-text keywords (name, skill, topic, etc.)
  final String keywords;

  /// Geographic filter, e.g. "San Francisco, CA"
  final String? location;

  /// Industry or vertical, e.g. "SaaS", "Healthcare"
  final String? industry;

  /// Job title filter, e.g. "VP Engineering"
  final String? title;

  /// Company name filter
  final String? companyName;

  /// Hard cap on how many prospects to return (per-scraper limit)
  final int maxResults;

  /// Optional hint to route the query to a specific scraper.
  /// Recognised values: 'linkedin', 'apollo', 'generic'.
  /// When null the aggregator tries every registered scraper.
  final String? sourceHint;

  /// Arbitrary key/value filters forwarded to scrapers that understand them.
  /// Example: {'seniorityLevel': 'Director', 'companySize': '50-200'}
  final Map<String, String> extraFilters;

  /// Build the query as a single search string (for scrapers that only accept
  /// one plain-text input, e.g. LinkedIn's people-search box).
  String toSearchString() {
    final parts = <String>[keywords];
    if (title != null) parts.add(title!);
    if (companyName != null) parts.add(companyName!);
    if (location != null) parts.add(location!);
    return parts.join(' ');
  }

  @override
  String toString() =>
      'ProspectQuery(keywords: $keywords, title: $title, '
      'company: $companyName, location: $location, max: $maxResults, '
      'source: $sourceHint)';
}
