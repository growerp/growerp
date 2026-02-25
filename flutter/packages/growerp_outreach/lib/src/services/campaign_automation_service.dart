import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'automation_orchestrator.dart';
import 'platform_automation_adapter.dart';
import '../models/platform_settings.dart';
import 'prospecting/prospect_aggregator_service.dart';
import 'prospecting/prospect_query.dart';
import 'prospecting/prospect_scrape_result.dart';

class CampaignAutomationService {
  final RestClient restClient;
  final AutomationOrchestrator _orchestrator;

  // Track active automations by campaignId
  final Map<String, bool> _activeCampaigns = {};

  // Optional: manually set leads per campaign (can be used programmatically)
  final Map<String, List<ProfileData>> _campaignLeads = {};

  CampaignAutomationService(
    this.restClient, {
    ProspectAggregatorService? prospectAggregator,
  }) : _orchestrator = AutomationOrchestrator(
         restClient,
         prospectAggregator: prospectAggregator,
       );

  /// Set target leads for a campaign (alternative to search-based targeting)
  void setTargetLeads(String campaignId, List<ProfileData> leads) {
    _campaignLeads[campaignId] = leads;
  }

  /// Get target leads for a campaign
  List<ProfileData>? getTargetLeads(String campaignId) {
    return _campaignLeads[campaignId];
  }

  /// Clear target leads for a campaign
  void clearTargetLeads(String campaignId) {
    _campaignLeads.remove(campaignId);
  }

  // ── Cold prospecting API ────────────────────────────────────────────────────

  /// Discover cold prospects **without** sending any messages.
  ///
  /// This is the first stage of a cold-outreach workflow:
  ///   1. Call [discoverProspects] to build a list of [ProspectScrapeResult].
  ///   2. Review / filter the results in the UI.
  ///   3. Call [prospectForCampaign] to persist them as `PENDING` messages
  ///      against a specific campaign so they can be messaged later.
  ///
  /// [query] drives what is searched and on which scraper(s):
  ///   - Set [ProspectQuery.sourceHint] to `'linkedin'`, `'apollo'`, or
  ///     `'generic'` to restrict to a single scraper.
  ///   - Leave it null to run all scrapers and merge results.
  Future<List<ProspectScrapeResult>> discoverProspects(
    ProspectQuery query,
  ) async {
    debugPrint('[CampaignAutomationService] Discovering prospects: $query');
    return _orchestrator.discoverProspects(query);
  }

  /// Run prospect discovery for [campaign] and persist the results as
  /// `PENDING` outreach messages on the specified [platform].
  ///
  /// This is a convenience wrapper that combines [discoverProspects] with
  /// the backend persistence step so callers can trigger the full
  /// "find + save" pipeline in one call.
  ///
  /// [sourceHint] overrides [campaign.targetAudience] scraper routing.
  Future<int> prospectForCampaign({
    required OutreachCampaign campaign,
    required String platform,
    String? sourceHint,
  }) async {
    if (campaign.campaignId == null) return 0;

    final query = ProspectQuery(
      keywords: campaign.targetAudience ?? '',
      maxResults: campaign.dailyLimitPerPlatform,
      sourceHint: sourceHint,
    );

    final prospects = await discoverProspects(query);

    int saved = 0;
    for (final p in prospects) {
      try {
        await restClient.createOutreachMessage(
          marketingCampaignId: campaign.campaignId!,
          platform: platform,
          recipientName: p.name,
          recipientHandle: p.handle,
          recipientProfileUrl: p.profileUrl,
          recipientEmail: p.email,
          messageContent: '',
          status: 'PENDING',
        );
        saved++;
      } catch (e) {
        debugPrint('[CampaignAutomationService] Error saving prospect: $e');
      }
    }

    debugPrint(
      '[CampaignAutomationService] ✓ Saved $saved cold prospects '
      'for campaign ${campaign.campaignId} on $platform',
    );
    return saved;
  }

  // ── Lead conversion ────────────────────────────────────────────────────────

  /// Promote an [OutreachMessage] (status RESPONDED or PENDING) into a
  /// proper GrowERP lead and stamp the message row with `CONVERTED`.
  ///
  /// **This is the boundary between the outreach world and the CRM world.**
  ///
  /// What happens:
  ///   1. `POST /User` creates `User(role: Role.lead)` — the standard GrowERP
  ///      lead record, indistinguishable from any other inbound lead.
  ///   2. `PATCH /OutreachMessage` sets `status = CONVERTED` and stores
  ///      `convertedPartyId` so the outreach row permanently links to the
  ///      CRM record.
  ///   3. The caller can then create an `Opportunity` (stage: Prospecting)
  ///      against the returned partyId using the existing CRM BLoC.
  ///
  /// Returns the partyId of the newly created lead, or null on failure.
  Future<String?> convertProspectToLead({
    required String messageId,
    required String firstName,
    String? lastName,
    String? email,
    String? companyName,
    String? title,
  }) async {
    try {
      // 1. Materialise the lead in GrowERP
      final newLead = await restClient.createUser(
        user: User(
          firstName: firstName,
          lastName: lastName ?? '',
          email: email ?? '',
          loginName: email ?? '',
          role: Role.lead,
          company: companyName != null
              ? Company(name: companyName, role: Role.lead)
              : null,
        ),
      );

      final partyId = newLead.partyId;

      // 2. Link the outreach row to the new lead
      await restClient.updateOutreachMessageStatus(
        messageId: messageId,
        status: 'CONVERTED',
        convertedPartyId: partyId,
      );

      debugPrint(
        '[CampaignAutomationService] ✓ Converted prospect '
        '$firstName → lead partyId=$partyId',
      );
      return partyId;
    } catch (e) {
      debugPrint('[CampaignAutomationService] Conversion failed: $e');
      return null;
    }
  }

  Future<void> startCampaign(OutreachCampaign campaign) async {
    if (campaign.campaignId == null) return;
    final campaignId = campaign.campaignId!;

    if (_activeCampaigns[campaignId] == true) return;

    // 1. Notify backend
    await restClient.startCampaignAutomation(marketingCampaignId: campaignId);
    _activeCampaigns[campaignId] = true;

    // 2. Initialize orchestrator for platforms
    List<String> platforms = [];
    try {
      // Parse JSON array string: ["EMAIL", "TWITTER"]
      final clean = campaign.platforms
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", "");
      platforms = clean
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error parsing platforms: $e');
    }

    if (platforms.isEmpty) {
      debugPrint('No platforms configured for campaign $campaignId');
      return;
    }

    await _orchestrator.initialize(platforms);

    // 3. Parse platform-specific settings
    final platformSettings = PlatformSettings.fromJson(
      campaign.platformSettings,
    );

    // 4. Get target leads if available (from programmatic API or parsed from targetAudience)
    final targetLeads = _getTargetLeads(campaign);

    // 5. Run automation in background
    // Note: This runs for each platform sequentially for now
    for (final platform in platforms) {
      if (_activeCampaigns[campaignId] != true) break;

      // Get platform-specific settings with fallbacks to campaign defaults
      final config = platformSettings.getForPlatform(platform);
      final actionType = config?.actionType ?? _getDefaultAction(platform);
      final searchKeywords =
          config?.searchKeywords ?? campaign.targetAudience ?? '';
      final messageTemplate =
          config?.messageTemplate ?? campaign.messageTemplate ?? '';

      try {
        await _orchestrator.runAutomation(
          platform: platform,
          actionType: actionType,
          searchCriteria: searchKeywords,
          messageTemplate: messageTemplate,
          dailyLimit: campaign.dailyLimitPerPlatform,
          campaignId: campaignId,
          emailSubject: campaign.emailSubject,
          targetLeads: targetLeads,
          checkCancelled: () => _activeCampaigns[campaignId] != true,
        );
      } catch (e) {
        debugPrint('Error running automation for campaign $campaignId: $e');
        // Don't stop the whole campaign on one platform error, but log it
      }
    }

    // If finished naturally (not cancelled), mark as complete or paused?
    // For now, we leave it active until manually paused or daily limit reached
  }

  /// Get default action type for a platform
  String _getDefaultAction(String platform) {
    switch (platform.toUpperCase()) {
      case 'EMAIL':
        return 'send_email';
      case 'LINKEDIN':
        return 'message_connections';
      case 'TWITTER':
        return 'post_tweet';
      case 'SUBSTACK':
        return 'post_note';
      default:
        return 'send_message';
    }
  }

  /// Get target leads for a campaign
  ///
  /// Priority:
  /// 1. Programmatically set leads via [setTargetLeads]
  /// 2. JSON array in targetAudience field (if it starts with '[')
  /// 3. null (will use search-based approach)
  List<ProfileData>? _getTargetLeads(OutreachCampaign campaign) {
    final campaignId = campaign.campaignId;
    if (campaignId == null) return null;

    // Check for programmatically set leads
    if (_campaignLeads.containsKey(campaignId)) {
      return _campaignLeads[campaignId];
    }

    // Check if targetAudience contains JSON leads
    final audience = campaign.targetAudience?.trim();
    if (audience != null && audience.startsWith('[')) {
      try {
        final List<dynamic> jsonLeads = jsonDecode(audience);
        return jsonLeads.map((lead) {
          if (lead is Map<String, dynamic>) {
            return ProfileData(
              name: lead['name']?.toString() ?? '',
              email: lead['email']?.toString(),
              handle: lead['handle']?.toString(),
              profileUrl: lead['profileUrl']?.toString(),
              company: lead['company']?.toString(),
              title: lead['title']?.toString(),
            );
          }
          return ProfileData(name: lead.toString());
        }).toList();
      } catch (e) {
        debugPrint('Failed to parse targetAudience as JSON leads: $e');
      }
    }

    return null;
  }

  Future<void> pauseCampaign(String campaignId) async {
    // 1. Notify backend
    await restClient.pauseCampaignAutomation(marketingCampaignId: campaignId);

    // 2. Stop local automation
    _activeCampaigns[campaignId] = false;
  }

  Future<CampaignProgress> getProgress(String campaignId) async {
    return await restClient.getCampaignProgress(
      marketingCampaignId: campaignId,
    );
  }

  bool isCampaignActive(String campaignId) {
    return _activeCampaigns[campaignId] ?? false;
  }
}
