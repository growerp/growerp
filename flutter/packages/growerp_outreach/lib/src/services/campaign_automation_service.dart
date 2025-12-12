import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:growerp_models/growerp_models.dart';
import 'automation_orchestrator.dart';

class CampaignAutomationService {
  final RestClient restClient;
  final AutomationOrchestrator _orchestrator;

  // Track active automations by campaignId
  final Map<String, bool> _activeCampaigns = {};

  CampaignAutomationService(this.restClient)
      : _orchestrator = AutomationOrchestrator(restClient);

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

    // 3. Run automation in background
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
