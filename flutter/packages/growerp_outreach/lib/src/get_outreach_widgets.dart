/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import '../growerp_outreach.dart';

/// Returns widget mappings for the outreach package
Map<String, GrowerpWidgetBuilder> getOutreachWidgets() {
  return {
    'CampaignListScreen': (args) => const CampaignListScreen(),
    'AutomationScreen': (args) => const AutomationScreen(),
    'PlatformConfigListScreen': (args) => const PlatformConfigListScreen(),
    'OutreachMessageList': (args) => const OutreachMessageList(),
  };
}

/// Returns widget metadata with icons for the outreach package
List<WidgetMetadata> getOutreachWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'CampaignListScreen',
      description: 'List of outreach campaigns',
      iconName: 'campaign',
      keywords: ['campaign', 'outreach', 'marketing', 'email'],
      builder: (args) => const CampaignListScreen(),
    ),
    WidgetMetadata(
      widgetName: 'AutomationScreen',
      description: 'Campaign automation management',
      iconName: 'autorenew',
      keywords: ['automation', 'workflow', 'automatic', 'schedule'],
      builder: (args) => const AutomationScreen(),
    ),
    WidgetMetadata(
      widgetName: 'PlatformConfigListScreen',
      description: 'Platform configuration settings',
      iconName: 'hub',
      keywords: ['platform', 'config', 'integration', 'setup'],
      builder: (args) => const PlatformConfigListScreen(),
    ),
    WidgetMetadata(
      widgetName: 'OutreachMessageList',
      description: 'List of outreach messages',
      iconName: 'message',
      keywords: ['message', 'outreach', 'communication', 'email'],
      builder: (args) => const OutreachMessageList(),
    ),
  ];
}
