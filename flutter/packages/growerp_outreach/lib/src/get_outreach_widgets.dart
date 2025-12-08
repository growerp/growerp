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
