/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:growerp_core/growerp_core.dart';
import '../growerp_marketing.dart';

/// Returns widget mappings for the marketing package
Map<String, GrowerpWidgetBuilder> getMarketingWidgets() {
  return {
    'ContentPlanList': (args) => const ContentPlanList(),
    'SocialPostList': (args) => const SocialPostList(),
    'PersonaList': (args) => const PersonaList(),
    'LandingPageList': (args) => const LandingPageList(),
    'AssessmentList': (args) => const AssessmentList(),
  };
}
