/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:growerp_models/growerp_models.dart';

List<OutreachCampaign> campaigns = [
  const OutreachCampaign(
    pseudoId: '1',
    name: 'Campaign 1',
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[EMAIL]',
    targetAudience: 'Audience 1',
    messageTemplate: 'Template 1',
    emailSubject: 'Subject 1',
    dailyLimitPerPlatform: 50,
  ),
  const OutreachCampaign(
    pseudoId: '2',
    name: 'Campaign 2',
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
    status: 'MKTG_CAMP_PLANNED',
    platforms: '[TWITTER]',
    targetAudience: 'Audience 3',
    messageTemplate: 'Template 3',
    emailSubject: 'Subject 3',
    dailyLimitPerPlatform: 20,
  ),
];

List<OutreachCampaign> updatedCampaigns = [
  const OutreachCampaign(
    pseudoId: '1',
    name: 'Campaign 1 Updated',
    status: 'MKTG_CAMP_APPROVED',
    platforms: '[EMAIL, LINKEDIN]',
    targetAudience: 'Audience 1 Updated',
    messageTemplate: 'Template 1 Updated',
    emailSubject: 'Subject 1 Updated',
    dailyLimitPerPlatform: 60,
  ),
  const OutreachCampaign(
    pseudoId: '2',
    name: 'Campaign 2 Updated',
    status: 'MKTG_CAMP_APPROVED',
    platforms: '[LINKEDIN, TWITTER]',
    targetAudience: 'Audience 2 Updated',
    messageTemplate: 'Template 2 Updated',
    emailSubject: 'Subject 2 Updated',
    dailyLimitPerPlatform: 110,
  ),
  const OutreachCampaign(
    pseudoId: '3',
    name: 'Campaign 3 Updated',
    status: 'MKTG_CAMP_CANCELLED',
    platforms: '[TWITTER, FACEBOOK]',
    targetAudience: 'Audience 3 Updated',
    messageTemplate: 'Template 3 Updated',
    emailSubject: 'Subject 3 Updated',
    dailyLimitPerPlatform: 30,
  ),
];
