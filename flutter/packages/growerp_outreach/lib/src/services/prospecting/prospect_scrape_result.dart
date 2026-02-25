import '../platform_automation_adapter.dart';

/// Enriched prospect record returned by every [ProspectScraper].
///
/// Superset of [ProfileData] — adds provenance, quality signals and
/// a richer set of contact fields discovered during scraping.
class ProspectScrapeResult {
  const ProspectScrapeResult({
    required this.name,
    required this.source,
    this.sourceId,
    this.profileUrl,
    this.handle,
    this.email,
    this.phone,
    this.company,
    this.title,
    this.location,
    this.industry,
    this.connectionDegree,
    this.tags = const [],
    this.confidence = 1.0,
    this.scrapedAt,
    this.rawData = const {},
  });

  // ── Identity ────────────────────────────────────────────────────────────────

  /// Full name of the prospect
  final String name;

  /// Human-readable name of the data source, e.g. 'linkedin', 'apollo',
  /// 'generic:https://example.com'
  final String source;

  /// Native record ID on the source platform (e.g. LinkedIn member URN)
  final String? sourceId;

  // ── Contact ─────────────────────────────────────────────────────────────────

  /// Canonical profile URL on the source platform
  final String? profileUrl;

  /// Social handle (Twitter @handle, LinkedIn vanity slug, etc.)
  final String? handle;

  /// Primary email address (may be null until enriched)
  final String? email;

  /// Phone number
  final String? phone;

  // ── Professional context ────────────────────────────────────────────────────

  final String? company;
  final String? title;
  final String? location;
  final String? industry;

  /// LinkedIn connection degree: 1, 2, 3+, or null when unknown.
  final int? connectionDegree;

  /// Arbitrary labels discovered during scraping, e.g. ['open-to-work',
  /// 'hiring', 'premium-member']
  final List<String> tags;

  // ── Quality signals ──────────────────────────────────────────────────────────

  /// Confidence that this is a real, valid record (0.0–1.0).
  /// Scrapers should lower this when data was inferred rather than explicit.
  final double confidence;

  /// UTC timestamp when this record was scraped
  final DateTime? scrapedAt;

  /// Unstructured platform-specific data for debugging / future use
  final Map<String, dynamic> rawData;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Deduplication key: prefer email, fall back to normalised profile URL,
  /// then lowercase name.
  String get dedupeKey {
    if (email != null && email!.isNotEmpty) return email!.toLowerCase().trim();
    if (profileUrl != null && profileUrl!.isNotEmpty) {
      return profileUrl!.toLowerCase().replaceAll(RegExp(r'[/?#]$'), '').trim();
    }
    return name.toLowerCase().trim();
  }

  /// Convert to the legacy [ProfileData] used by messaging adapters.
  ProfileData toProfileData() => ProfileData(
    name: name,
    profileUrl: profileUrl,
    handle: handle,
    email: email,
    company: company,
    title: title,
  );

  ProspectScrapeResult copyWith({
    String? name,
    String? source,
    String? sourceId,
    String? profileUrl,
    String? handle,
    String? email,
    String? phone,
    String? company,
    String? title,
    String? location,
    String? industry,
    int? connectionDegree,
    List<String>? tags,
    double? confidence,
    DateTime? scrapedAt,
    Map<String, dynamic>? rawData,
  }) => ProspectScrapeResult(
    name: name ?? this.name,
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    profileUrl: profileUrl ?? this.profileUrl,
    handle: handle ?? this.handle,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    company: company ?? this.company,
    title: title ?? this.title,
    location: location ?? this.location,
    industry: industry ?? this.industry,
    connectionDegree: connectionDegree ?? this.connectionDegree,
    tags: tags ?? this.tags,
    confidence: confidence ?? this.confidence,
    scrapedAt: scrapedAt ?? this.scrapedAt,
    rawData: rawData ?? this.rawData,
  );

  @override
  String toString() =>
      'ProspectScrapeResult(name: $name, source: $source, '
      'email: $email, title: $title, company: $company, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}
