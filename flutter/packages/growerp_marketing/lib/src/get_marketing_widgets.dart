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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_marketing.dart';

/// Returns widget mappings for the marketing package
Map<String, GrowerpWidgetBuilder> getMarketingWidgets() {
  return {
    'MarketingSetupGuideScreen': (args) => const MarketingSetupGuideScreen(),
    'ContentPlanList': (args) => const ContentPlanList(),
    'SocialPostList': (args) => const SocialPostList(),
    'MasterContentList': (args) => const MasterContentList(),
    'PersonaList': (args) => const PersonaList(),
    'EmailSequenceList': (args) => const EmailSequenceList(),
    'SocialEngagementList': (args) => const SocialEngagementList(),
  };
}

/// Returns widget metadata with icons for the marketing package
List<WidgetMetadata> getMarketingWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'MarketingSetupGuideScreen',
      description: 'Step by step guide through the content machine',
      iconName: 'checklist',
      keywords: ['guide', 'setup', 'marketing', 'content', 'steps'],
      builder: (args) => const MarketingSetupGuideScreen(),
    ),
    WidgetMetadata(
      widgetName: 'SocialPostDialog',
      description:
          'Create or edit a social post. Pass postId to edit an '
          'existing post; omit it to create a new one.',
      iconName: 'share',
      keywords: ['add post', 'new post', 'edit post', 'social post'],
      parameters: {
        'postId': 'open this post for editing; omit to create new',
        'scheduledDate': 'scheduled date (DateTime) of a new post',
      },
      builder: (args) {
        final id = args?['postId']?.toString();
        if (id == null || id.isEmpty) {
          final scheduledDate = args?['scheduledDate'];
          return SocialPostDetailScreen(
            socialPost: scheduledDate is DateTime
                // the detail screen's own defaults; it creates rather than
                // updates because there is no postId
                ? SocialPost(
                    type: 'PAIN',
                    status: 'DRAFT',
                    scheduledDate: scheduledDate,
                  )
                : null,
          );
        }
        return AsyncRecordDialog<SocialPost>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getSocialPosts(
              postId: id,
              limit: 1,
            );
            return r.socialPosts.isNotEmpty ? r.socialPosts.first : null;
          },
          onLoaded: (post) => SocialPostDetailScreen(socialPost: post),
        );
      },
    ),
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
      description:
          'Platform-neutral content authored once, adapted to all platforms',
      iconName: 'auto_awesome',
      keywords: [
        'master',
        'content',
        'adapt',
        'platform',
        'article',
        'posting',
      ],
      builder: (args) => const MasterContentList(),
    ),
    WidgetMetadata(
      widgetName: 'PersonaList',
      description: 'List of marketing personas',
      iconName: 'person_outline',
      keywords: ['persona', 'target', 'audience', 'profile'],
      builder: (args) => const PersonaList(),
    ),
  ];
}
