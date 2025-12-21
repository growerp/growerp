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

/// Returns widget metadata with icons for the marketing package
List<WidgetMetadata> getMarketingWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'ContentPlanList',
      description: 'List of content marketing plans',
      iconName: 'campaign',
      keywords: ['content', 'plan', 'marketing', 'schedule'],
      builder: (args) => const ContentPlanList(),
    ),
    WidgetMetadata(
      widgetName: 'SocialPostList',
      description: 'List of social media posts',
      iconName: 'share',
      keywords: ['social', 'post', 'media', 'facebook', 'twitter'],
      builder: (args) => const SocialPostList(),
    ),
    WidgetMetadata(
      widgetName: 'PersonaList',
      description: 'List of marketing personas',
      iconName: 'person_outline',
      keywords: ['persona', 'target', 'audience', 'profile'],
      builder: (args) => const PersonaList(),
    ),
    WidgetMetadata(
      widgetName: 'LandingPageList',
      description: 'List of landing pages',
      iconName: 'web',
      keywords: ['landing', 'page', 'website', 'conversion'],
      builder: (args) => const LandingPageList(),
    ),
    WidgetMetadata(
      widgetName: 'AssessmentList',
      description: 'List of marketing assessments',
      iconName: 'quiz',
      keywords: ['assessment', 'quiz', 'survey', 'evaluation'],
      builder: (args) => const AssessmentList(),
    ),
  ];
}
