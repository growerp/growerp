/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
    'LinkedInSendQueueScreen': (args) => const LinkedInSendQueueScreen(),
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
    WidgetMetadata(
      widgetName: 'LinkedInSendQueueScreen',
      description: 'Assisted 1-click LinkedIn send queue',
      iconName: 'send',
      keywords: ['linkedin', 'send', 'queue', 'outreach', 'message'],
      builder: (args) => const LinkedInSendQueueScreen(),
    ),
  ];
}
