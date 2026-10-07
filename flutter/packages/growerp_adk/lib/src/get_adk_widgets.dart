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

import 'agent_control_guide_screen.dart';

/// Widget metadata of the adk package. A widget name ending in 'GuideScreen'
/// also lists the screen in System Setup > Guides.
List<WidgetMetadata> getAdkWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'AgentControlGuideScreen',
      description: 'Step by step guide to controlling AI agents',
      iconName: 'checklist',
      keywords: ['guide', 'agent', 'control', 'approval', 'steps'],
      builder: (args) => const AgentControlGuideScreen(),
    ),
  ];
}
