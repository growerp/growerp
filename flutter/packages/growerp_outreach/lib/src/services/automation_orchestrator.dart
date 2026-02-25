import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'platform_automation_adapter.dart';
import 'adapters/email_automation_adapter.dart';
import 'adapters/linkedin_automation_adapter.dart';
import 'adapters/x_automation_adapter.dart';
import 'adapters/substack_automation_adapter.dart';
import '../utils/rate_limiter.dart';
import 'prospecting/prospect_aggregator_service.dart';
import 'prospecting/prospect_query.dart';
import 'prospecting/prospect_scrape_result.dart';

/// Orchestrates automation across multiple platforms
///
/// This class manages the execution of outreach campaigns across
/// different platforms, handling platform-specific adapters and
/// coordinating the automation workflow.
///
/// Prospect discovery is delegated to [ProspectAggregatorService] which
/// dispatches searches to the appropriate scraper (LinkedIn, Apollo, generic
/// web) based on the query's [ProspectQuery.sourceHint].  Pass a custom
/// [prospectAggregator] to override the default configuration (e.g. for
/// testing or to inject a pre-authenticated scraper).
class AutomationOrchestrator {
  AutomationOrchestrator(
    this.restClient, {
    ProspectAggregatorService? prospectAggregator,
  }) : _prospectAggregator = prospectAggregator ?? ProspectAggregatorService();

  final RestClient restClient;
  final ProspectAggregatorService _prospectAggregator;
  final Map<String, PlatformAutomationAdapter> _adapters = {};
  final Map<String, RateLimiter> _rateLimiters = {};

  /// Get or create a rate limiter for a platform
  RateLimiter _getRateLimiter(String platform) {
    return _rateLimiters.putIfAbsent(platform, () {
      // Configure rate limits per platform
      // These are conservative defaults to avoid platform detection
      switch (platform.toUpperCase()) {
        case 'EMAIL':
          // 60 emails per hour (1 per minute)
          return RateLimiter(
            name: 'EMAIL',
            maxRequests: 60,
            window: const Duration(hours: 1),
          );
        case 'LINKEDIN':
          // 20 actions per hour (to stay under radar)
          return RateLimiter(
            name: 'LINKEDIN',
            maxRequests: 20,
            window: const Duration(hours: 1),
          );
        case 'TWITTER':
          // 15 actions per hour (Twitter is strict)
          return RateLimiter(
            name: 'TWITTER',
            maxRequests: 15,
            window: const Duration(hours: 1),
          );
        case 'SUBSTACK':
          // 30 actions per hour (Substack is more lenient)
          return RateLimiter(
            name: 'SUBSTACK',
            maxRequests: 30,
            window: const Duration(hours: 1),
          );
        default:
          return RateLimiter(
            name: platform,
            maxRequests: 30,
            window: const Duration(hours: 1),
          );
      }
    });
  }

  /// Initialize adapters for the specified platforms and the prospect
  /// aggregator (scrapers are initialised lazily when first used).
  Future<void> initialize(List<String> platforms) async {
    for (final platform in platforms) {
      final adapter = _createAdapter(platform);
      if (adapter != null) {
        await adapter.initialize();
        _adapters[platform] = adapter;
      }
    }
    // Initialise scrapers (each one no-ops if already initialised)
    await _prospectAggregator.initialize();
  }

  /// Run automation for a specific platform
  ///
  /// The [actionType] determines what action to perform:
  /// - EMAIL: 'send_email'
  /// - LINKEDIN: 'message_connections', 'search_and_connect'
  /// - TWITTER: 'post_tweet', 'follow_profiles', 'send_dms'
  /// - SUBSTACK: 'post_note', 'subscribe', 'comment'
  ///
  /// If [targetLeads] is provided and non-empty, those profiles will be used
  /// directly instead of searching with [searchCriteria].
  Future<void> runAutomation({
    required String platform,
    required String actionType,
    required String searchCriteria,
    required String messageTemplate,
    required int dailyLimit,
    required String campaignId,
    String? emailSubject,
    List<ProfileData>? targetLeads,
    required bool Function() checkCancelled,
  }) async {
    final adapter = _adapters[platform];
    if (adapter == null) {
      throw Exception('Platform $platform not initialized');
    }

    // Check if logged in
    final isLoggedIn = await adapter.isLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Not logged in to $platform');
    }

    // Handle broadcast actions (no target profiles needed)
    if (_isBroadcastAction(actionType)) {
      await _runBroadcastAction(
        adapter: adapter,
        platform: platform,
        actionType: actionType,
        messageTemplate: messageTemplate,
        campaignId: campaignId,
        checkCancelled: checkCancelled,
      );
      return;
    }

    // SEARCH-TO-LEADS FLOW: For search/follow actions, save results as PENDING
    if (_isSearchOnlyAction(actionType)) {
      await _runSearchAndSaveLeads(
        adapter: adapter,
        platform: platform,
        searchCriteria: searchCriteria,
        campaignId: campaignId,
        dailyLimit: dailyLimit,
        // Route to the matching scraper when the platform name aligns with a
        // known scraper hint, otherwise use all scrapers.
        sourceHint: _platformToScraperHint(platform),
      );
      return;
    }

    // DM-FROM-LEADS FLOW: For DM actions, fetch PENDING leads first
    List<ProfileData> profiles;
    if (_isDmAction(actionType)) {
      profiles = await _fetchPendingLeads(campaignId, platform);
      if (profiles.isEmpty && targetLeads != null && targetLeads.isNotEmpty) {
        profiles = targetLeads;
      }
      debugPrint('Using ${profiles.length} leads for DM on $platform');
    } else if (targetLeads != null && targetLeads.isNotEmpty) {
      profiles = targetLeads;
      debugPrint('Using ${profiles.length} target leads for $platform');
    } else if (searchCriteria.isNotEmpty) {
      profiles = await adapter.searchProfiles(searchCriteria);
      debugPrint('Found ${profiles.length} profiles via search for $platform');
    } else {
      debugPrint('No search criteria or target leads for $platform');
      return;
    }

    // Get rate limiter for this platform
    final rateLimiter = _getRateLimiter(platform);

    // Process profiles up to daily limit
    int sent = 0;
    for (final profile in profiles) {
      if (checkCancelled()) break;
      if (sent >= dailyLimit) break;

      try {
        // Use rate limiter to control send rate
        await rateLimiter.execute(() async {
          // Personalize message
          final message = _personalizeMessage(messageTemplate, profile);

          // Execute action based on actionType
          await _executeTargetedAction(
            adapter: adapter,
            platform: platform,
            actionType: actionType,
            profile: profile,
            message: message,
            campaignId: campaignId,
            emailSubject: emailSubject,
          );

          // Record success in backend
          await restClient.createOutreachMessage(
            marketingCampaignId: campaignId,
            platform: platform,
            recipientName: profile.name,
            recipientHandle: profile.handle,
            recipientProfileUrl: profile.profileUrl,
            recipientEmail: profile.email,
            messageContent: message,
            status: 'SENT',
          );

          sent++;

          // Add small random delay on top of rate limiting to appear more human
          if (!checkCancelled()) {
            final jitter =
                DateTime.now().millisecond % 10; // 0-10 seconds extra
            await Future.delayed(Duration(seconds: jitter));
          }
        });
      } catch (e) {
        // Log error and continue
        debugPrint('Error sending to ${profile.name}: $e');

        // Record failure in backend
        try {
          await restClient.createOutreachMessage(
            marketingCampaignId: campaignId,
            platform: platform,
            recipientName: profile.name,
            recipientHandle: profile.handle,
            recipientProfileUrl: profile.profileUrl,
            recipientEmail: profile.email,
            messageContent: _personalizeMessage(messageTemplate, profile),
            status: 'FAILED',
          );
        } catch (_) {
          // Ignore backend error if logging fails
        }
      }
    }

    // Log rate limiter stats at end
    debugPrint('Rate limiter stats: ${rateLimiter.getStats()}');
  }

  /// Cleanup all adapters, scrapers and reset rate limiters
  Future<void> cleanup() async {
    for (final adapter in _adapters.values) {
      await adapter.cleanup();
    }
    _adapters.clear();

    for (final limiter in _rateLimiters.values) {
      limiter.reset();
    }
    _rateLimiters.clear();

    await _prospectAggregator.cleanup();
  }

  /// Get rate limiter stats for a platform
  Map<String, dynamic>? getRateLimiterStats(String platform) {
    return _rateLimiters[platform]?.getStats();
  }

  PlatformAutomationAdapter? _createAdapter(String platform) {
    switch (platform.toUpperCase()) {
      case 'EMAIL':
        return EmailAutomationAdapter(restClient);
      case 'LINKEDIN':
        return LinkedInAutomationAdapter();
      case 'TWITTER':
        return XAutomationAdapter();
      case 'SUBSTACK':
        return SubstackAutomationAdapter();
      default:
        return null;
    }
  }

  String _personalizeMessage(String template, ProfileData profile) {
    return template
        .replaceAll('{name}', profile.name)
        .replaceAll('{company}', profile.company ?? '')
        .replaceAll('{title}', profile.title ?? '');
  }

  /// Map a messaging-platform name to the scraper source hint used by the
  /// [ProspectAggregatorService].  Returns null for platforms without a
  /// dedicated scraper so the aggregator tries all of them.
  String? _platformToScraperHint(String platform) {
    switch (platform.toUpperCase()) {
      case 'LINKEDIN':
        return 'linkedin';
      case 'APOLLO':
        return 'apollo';
      default:
        // EMAIL, TWITTER, SUBSTACK → no scraper restriction
        return null;
    }
  }

  /// Check if an action is a broadcast (doesn't target specific profiles)
  bool _isBroadcastAction(String actionType) {
    return const ['post_tweet', 'post_note'].contains(actionType);
  }

  /// Run a broadcast action (post without targeting specific profiles)
  Future<void> _runBroadcastAction({
    required PlatformAutomationAdapter adapter,
    required String platform,
    required String actionType,
    required String messageTemplate,
    required String campaignId,
    required bool Function() checkCancelled,
  }) async {
    if (checkCancelled()) return;

    final rateLimiter = _getRateLimiter(platform);

    try {
      await rateLimiter.execute(() async {
        switch (actionType) {
          case 'post_tweet':
            // X/Twitter tweet
            if (adapter is XAutomationAdapter) {
              await adapter.postTweet(messageTemplate);
            }
            break;
          case 'post_note':
            // Substack note
            if (adapter is SubstackAutomationAdapter) {
              await adapter.postNote(messageTemplate);
            }
            break;
        }

        // Record success
        await restClient.createOutreachMessage(
          marketingCampaignId: campaignId,
          platform: platform,
          messageContent: messageTemplate,
          status: 'SENT',
        );

        debugPrint('✓ Broadcast $actionType on $platform');
      });
    } catch (e) {
      debugPrint('Error broadcasting on $platform: $e');
      try {
        await restClient.createOutreachMessage(
          marketingCampaignId: campaignId,
          platform: platform,
          messageContent: messageTemplate,
          status: 'FAILED',
        );
      } catch (_) {}
    }
  }

  /// Execute a targeted action on a specific profile
  Future<void> _executeTargetedAction({
    required PlatformAutomationAdapter adapter,
    required String platform,
    required String actionType,
    required ProfileData profile,
    required String message,
    required String campaignId,
    String? emailSubject,
  }) async {
    switch (actionType) {
      // Email actions
      case 'send_email':
        await adapter.sendDirectMessage(
          profile,
          message,
          campaignId: campaignId,
          subject: emailSubject,
        );
        break;

      // LinkedIn actions
      case 'message_connections':
        await adapter.sendDirectMessage(
          profile,
          message,
          campaignId: campaignId,
        );
        break;
      case 'search_and_connect':
        await adapter.sendConnectionRequest(profile, message);
        break;

      // Twitter/X actions
      case 'follow_profiles':
        await adapter.sendConnectionRequest(profile, message);
        break;
      case 'send_dms':
        await adapter.sendDirectMessage(
          profile,
          message,
          campaignId: campaignId,
        );
        break;

      // Substack actions
      case 'subscribe':
        await adapter.sendConnectionRequest(profile, message);
        break;
      case 'comment':
        if (adapter is SubstackAutomationAdapter) {
          await adapter.commentOnLatestPost(profile, message);
        }
        break;

      // Default fallback
      default:
        await adapter.sendConnectionRequest(profile, message);
    }
  }

  /// Check if action is a search-only action (saves leads but doesn't message)
  bool _isSearchOnlyAction(String actionType) {
    return [
      'follow_profiles',
      'search_and_connect',
      'subscribe',
    ].contains(actionType);
  }

  /// Check if action is a DM action (fetches leads then messages)
  bool _isDmAction(String actionType) {
    return ['send_dms'].contains(actionType);
  }

  /// Discover cold prospects and save them as PENDING leads.
  ///
  /// Delegates to [ProspectAggregatorService] which dispatches to the correct
  /// scraper (LinkedIn, Apollo, generic) based on [sourceHint]:
  ///
  ///   - `'linkedin'`  → LinkedIn people-search scraper
  ///   - `'apollo'`    → Apollo.io search scraper
  ///   - `'generic'` or any `'http…'` URL → general web scraper
  ///   - `null`        → all registered scrapers tried in priority order
  ///
  /// Results are deduplicated and ranked by the aggregator before the top
  /// [dailyLimit] records are persisted as `PENDING` outreach messages.
  Future<void> _runSearchAndSaveLeads({
    // ignore: unused_element
    required PlatformAutomationAdapter adapter, // kept for interface compat
    required String platform,
    required String searchCriteria,
    required String campaignId,
    required int dailyLimit,
    String? sourceHint,
  }) async {
    if (searchCriteria.isEmpty) {
      debugPrint('[AutomationOrchestrator] No search criteria for $platform');
      return;
    }

    // Build a structured query from the free-text search criteria.
    // Criteria may be a plain keyword string or 'title:X company:Y location:Z'
    // encoded as key:value pairs separated by spaces.
    final query = _buildProspectQuery(
      searchCriteria: searchCriteria,
      maxResults: dailyLimit,
      sourceHint: sourceHint,
    );

    final prospects = await _prospectAggregator.scrape(query);
    debugPrint(
      '[AutomationOrchestrator] Aggregator found ${prospects.length} '
      'prospects for $platform',
    );

    int saved = 0;
    for (final prospect in prospects) {
      if (saved >= dailyLimit) break;

      try {
        await restClient.createOutreachMessage(
          marketingCampaignId: campaignId,
          platform: platform,
          recipientName: prospect.name,
          recipientHandle: prospect.handle,
          recipientProfileUrl: prospect.profileUrl,
          recipientEmail: prospect.email,
          messageContent: '', // Personalised at send time
          status: 'PENDING',
        );
        saved++;
      } catch (e) {
        debugPrint(
          '[AutomationOrchestrator] Error saving prospect ${prospect.name}: $e',
        );
      }
    }

    debugPrint(
      '[AutomationOrchestrator] ✓ Saved $saved prospects as PENDING '
      'for $platform (source: ${query.sourceHint ?? "all scrapers"}).',
    );
  }

  /// Parse a search-criteria string into a [ProspectQuery].
  ///
  /// Supports optional structured prefix notation:
  ///
  ///   `title:"VP Engineering" company:Acme location:"San Francisco"`
  ///
  /// Any tokens without a recognised prefix are treated as plain [keywords].
  ProspectQuery _buildProspectQuery({
    required String searchCriteria,
    required int maxResults,
    String? sourceHint,
  }) {
    // Regex to extract key:"quoted value" or key:value pairs
    final tagRe = RegExp(
      r'(title|company|location|industry|seniority):(?:"([^"]+)"|([^\s]+))',
      caseSensitive: false,
    );

    String? title;
    String? company;
    String? location;
    String? industry;
    final extras = <String, String>{};
    var remaining = searchCriteria;

    for (final m in tagRe.allMatches(searchCriteria)) {
      final key = m.group(1)!.toLowerCase();
      final value = (m.group(2) ?? m.group(3))!;
      switch (key) {
        case 'title':
          title = value;
          break;
        case 'company':
          company = value;
          break;
        case 'location':
          location = value;
          break;
        case 'industry':
          industry = value;
          break;
        default:
          extras[key] = value;
      }
      remaining = remaining.replaceFirst(m.group(0)!, '').trim();
    }

    return ProspectQuery(
      keywords: remaining.isEmpty ? searchCriteria : remaining,
      title: title,
      companyName: company,
      location: location,
      industry: industry,
      maxResults: maxResults,
      sourceHint: sourceHint,
      extraFilters: extras,
    );
  }

  /// Expose direct prospecting so callers (e.g. [CampaignAutomationService])
  /// can run a standalone scrape without executing a full campaign send.
  Future<List<ProspectScrapeResult>> discoverProspects(
    ProspectQuery query,
  ) async {
    await _prospectAggregator.initialize();
    return _prospectAggregator.scrape(query);
  }

  /// Fetch PENDING leads from backend for a campaign
  Future<List<ProfileData>> _fetchPendingLeads(
    String campaignId,
    String platform,
  ) async {
    try {
      final messages = await restClient.listOutreachMessages(
        marketingCampaignId: campaignId,
        status: 'PENDING',
      );

      return messages.messages
          .where((m) => m.platform.toUpperCase() == platform.toUpperCase())
          .map(
            (m) => ProfileData(
              name: m.recipientName ?? '',
              handle: m.recipientHandle,
              profileUrl: m.recipientProfileUrl,
              email: m.recipientEmail,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending leads: $e');
      return [];
    }
  }
}
