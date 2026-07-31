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

import 'package:growerp_models/growerp_models.dart';

List<OutreachCampaign> campaigns = [
  const OutreachCampaign(
    pseudoId: '1',
    name: 'Campaign 1',
    description: 'Description 1',
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[EMAIL]',
    targetAudience: 'Audience 1',
    messageTemplate: 'Template 1',
    emailSubject: 'Subject 1',
    dailyLimitPerPlatform: 50,
    // send window in UTC hours, the UI shows/enters them in local time
    sendFromHour: 6,
    sendToHour: 14,
  ),
  const OutreachCampaign(
    pseudoId: '2',
    name: 'Campaign 2',
    description: 'Description 2',
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[LINKEDIN]',
    targetAudience: 'Audience 2',
    messageTemplate: 'Template 2',
    emailSubject: 'Subject 2',
    dailyLimitPerPlatform: 100,
  ),
  const OutreachCampaign(
    pseudoId: '3',
    name: 'Campaign 3',
    description: 'Description 3',
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[EMAIL, LINKEDIN]',
    targetAudience: 'Audience 3',
    messageTemplate: 'Template 3',
    emailSubject: 'Subject 3',
    dailyLimitPerPlatform: 20,
    // wraps over midnight UTC
    sendFromHour: 22,
    sendToHour: 3,
  ),
];

List<OutreachCampaign> updatedCampaigns = [
  const OutreachCampaign(
    pseudoId: '1',
    name: 'Campaign 1 Updated',
    description: 'Description 1 Updated',
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[EMAIL, LINKEDIN]',
    targetAudience: 'Audience 1 Updated',
    messageTemplate: 'Template 1 Updated',
    emailSubject: 'Subject 1 Updated',
    dailyLimitPerPlatform: 60,
    sendFromHour: 8,
    sendToHour: 16,
  ),
  const OutreachCampaign(
    pseudoId: '2',
    name: 'Campaign 2 Updated',
    description: 'Description 2 Updated',
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[LINKEDIN, EMAIL]',
    targetAudience: 'Audience 2 Updated',
    messageTemplate: 'Template 2 Updated',
    emailSubject: 'Subject 2 Updated',
    dailyLimitPerPlatform: 110,
    sendFromHour: 5,
    sendToHour: 9,
  ),
  const OutreachCampaign(
    pseudoId: '3',
    name: 'Campaign 3 Updated',
    description: 'Description 3 Updated',
    status: 'MKTG_CAMP_CANCELLED',
    platforms: '[LINKEDIN]',
    targetAudience: 'Audience 3 Updated',
    messageTemplate: 'Template 3 Updated',
    emailSubject: 'Subject 3 Updated',
    dailyLimitPerPlatform: 30,
  ),
];
