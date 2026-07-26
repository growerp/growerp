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
import '../growerp_marketing.dart';

/// Returns widget mappings for the marketing package
Map<String, GrowerpWidgetBuilder> getMarketingWidgets() {
  return {
    'ContentPlanList': (args) => const ContentPlanList(),
    'SocialPostList': (args) => const SocialPostList(),
    'MasterContentList': (args) => const MasterContentList(),
    'PersonaList': (args) => const PersonaList(),
    'EmailSequenceList': (args) => const EmailSequenceList(),
    'SocialEngagementList': (args) => const SocialEngagementList(),
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
      widgetName: 'MasterContentList',
      description: 'Platform-neutral content authored once, adapted to all platforms',
      iconName: 'auto_awesome',
      keywords: ['master', 'content', 'adapt', 'platform', 'article', 'posting'],
      builder: (args) => const MasterContentList(),
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
