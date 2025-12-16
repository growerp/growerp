import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'automation_orchestrator.dart';
import 'platform_automation_adapter.dart';

class CampaignAutomationService {
  final RestClient restClient;
  final AutomationOrchestrator _orchestrator;

  // Track active automations by campaignId
  final Map<String, bool> _activeCampaigns = {};

  // Optional: manually set leads per campaign (can be used programmatically)
  final Map<String, List<ProfileData>> _campaignLeads = {};

  CampaignAutomationService(this.restClient)
      : _orchestrator = AutomationOrchestrator(restClient);

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

    // 3. Get target leads if available (from programmatic API or parsed from targetAudience)
    final targetLeads = _getTargetLeads(campaign);

    // 4. Run automation in background
    // Note: This runs for each platform sequentially for now
    for (final platform in platforms) {
      if (_activeCampaigns[campaignId] != true) break;

      try {
        await _orchestrator.runAutomation(
          platform: platform,
          searchCriteria: campaign.targetAudience ?? '',
          messageTemplate: campaign.messageTemplate ?? '',
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
        marketingCampaignId: campaignId);
  }

  bool isCampaignActive(String campaignId) {
    return _activeCampaigns[campaignId] ?? false;
  }
}
