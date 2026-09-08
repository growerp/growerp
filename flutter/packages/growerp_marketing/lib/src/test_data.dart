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

List<Persona> personas = [
  const Persona(
    name: 'Alex Johnson',
    demographics: '35-45 years old, small business owner, urban location',
    painPoints: 'Struggling with cash flow management and scaling operations',
    goals: 'Achieve sustainable growth and improve profitability',
    toneOfVoice: 'Professional yet approachable',
  ),
  const Persona(
    name: 'Sarah Chen',
    demographics: '28-35 years old, startup founder, tech industry',
    painPoints:
        'Limited resources, time constraints, finding product-market fit',
    goals: 'Build a scalable product and secure Series A funding',
    toneOfVoice: 'Innovative and energetic',
  ),
  const Persona(
    name: 'Michael Rodriguez',
    demographics: '45-55 years old, established business owner, manufacturing',
    painPoints: 'Digital transformation challenges, workforce training',
    goals: 'Modernize operations and stay competitive',
    toneOfVoice: 'Traditional but open to change',
  ),
];

/// Updated persona test data for testing updates
List<Persona> updatedPersonas = [
  const Persona(
    name: 'Alex Johnson Updated',
    demographics: '40-50 years old, medium business owner, suburban location',
    painPoints: 'Scaling operations internationally and managing remote teams',
    goals: 'Expand to new markets and build a strong company culture',
    toneOfVoice: 'Confident and inspiring',
  ),
  const Persona(
    name: 'Sarah Chen Updated',
    demographics: '30-38 years old, CEO, SaaS industry',
    painPoints: 'Retaining talent, maintaining growth trajectory',
    goals: 'Achieve unicorn status and expand globally',
    toneOfVoice: 'Visionary and ambitious',
  ),
  const Persona(
    name: 'Michael Rodriguez Updated',
    demographics:
        '50-60 years old, industry veteran, manufacturing & logistics',
    painPoints: 'Supply chain optimization, sustainability requirements',
    goals: 'Lead industry transformation and mentor next generation',
    toneOfVoice: 'Wise and mentoring',
  ),
];

/// Content Plan test data
List<ContentPlan> contentPlans = [
  ContentPlan(
    theme: 'Digital Transformation Journey',
    weekStartDate: DateTime.now(),
  ),
  ContentPlan(
    theme: 'Customer Success Stories',
    weekStartDate: DateTime.now().add(const Duration(days: 7)),
  ),
  ContentPlan(
    theme: 'Industry Best Practices',
    weekStartDate: DateTime.now().add(const Duration(days: 14)),
  ),
];

/// Updated content plan test data for testing updates
List<ContentPlan> updatedContentPlans = [
  ContentPlan(
    theme: 'Digital Transformation Journey - Updated',
    weekStartDate: DateTime.now().add(const Duration(days: 1)),
  ),
  ContentPlan(
    theme: 'Customer Success Stories - Updated',
    weekStartDate: DateTime.now().add(const Duration(days: 8)),
  ),
  ContentPlan(
    theme: 'Industry Best Practices - Updated',
    weekStartDate: DateTime.now().add(const Duration(days: 15)),
  ),
];

/// Social Post test data
List<SocialPost> socialPosts = [
  const SocialPost(
    type: 'PAIN',
    platform: 'LINKEDIN',
    headline: 'Struggling with digital transformation?',
    draftContent:
        'Many businesses face challenges when modernizing their operations...',
    status: 'DRAFT',
  ),
  const SocialPost(
    type: 'NEWS',
    platform: 'TWITTER',
    headline: 'Exciting industry trends for 2025',
    draftContent:
        'The latest research shows significant shifts in business technology...',
    status: 'DRAFT',
  ),
  const SocialPost(
    type: 'PRIZE',
    platform: 'FACEBOOK',
    headline: 'Transform your business in 30 days',
    draftContent: 'Discover how our clients achieved remarkable results...',
    status: 'DRAFT',
  ),
];

/// Updated social post test data for testing updates
List<SocialPost> updatedSocialPosts = [
  const SocialPost(
    type: 'PAIN',
    platform: 'LINKEDIN',
    headline: 'Still struggling with digital transformation?',
    draftContent:
        'Updated: Many businesses face challenges when modernizing their operations...',
    status: 'READY',
  ),
  const SocialPost(
    type: 'NEWS',
    platform: 'TWITTER',
    headline: 'Breaking: Industry trends for 2025',
    draftContent:
        'Updated: The latest research shows significant shifts in business technology...',
    status: 'READY',
  ),
  const SocialPost(
    type: 'PRIZE',
    platform: 'INSTAGRAM',
    headline: 'Transform your business in just 30 days',
    draftContent:
        'Updated: Discover how our clients achieved remarkable results...',
    status: 'READY',
  ),
];

/// Master Content test data (platform-neutral, author-once)
List<MasterContent> masterContents = [
  const MasterContent(
    contentType: 'POSTING',
    pnpType: 'PAIN',
    title: 'Your spreadsheet is a single point of failure',
    body:
        'When the whole business runs on one spreadsheet, one wrong cell or a '
        'laptop crash can stop everything. There is a better way to run an SMB.',
    callToAction: 'See how GrowERP helps',
    status: 'DRAFT',
  ),
  const MasterContent(
    contentType: 'ARTICLE',
    pnpType: 'NEWS',
    title: 'How one SMB replaced six tools with one system',
    body:
        'A small distributor was juggling six disconnected tools. Here is how '
        'moving to a single ERP cut re-keying, errors and cost.',
    callToAction: 'Read the story',
    status: 'DRAFT',
  ),
  const MasterContent(
    contentType: 'MESSAGE',
    pnpType: 'PRIZE',
    title: 'Start the free assessment',
    body:
        'Curious whether GrowERP fits how you run your business? The free '
        'assessment takes two minutes and shows your ERP fit.',
    callToAction: 'Start the free assessment',
    status: 'DRAFT',
  ),
];

List<MasterContent> updatedMasterContents = [
  const MasterContent(
    contentType: 'POSTING',
    pnpType: 'PAIN',
    title: 'Still running the company on a spreadsheet?',
    body:
        'Updated: When the whole business runs on one spreadsheet, one wrong '
        'cell can stop everything. There is a better way to run an SMB.',
    callToAction: 'See how GrowERP helps',
    status: 'APPROVED',
  ),
  const MasterContent(
    contentType: 'ARTICLE',
    pnpType: 'NEWS',
    title: 'One system instead of six tools: an SMB story',
    body:
        'Updated: A small distributor was juggling six disconnected tools. '
        'Here is how a single ERP cut re-keying, errors and cost.',
    callToAction: 'Read the story',
    status: 'APPROVED',
  ),
  const MasterContent(
    contentType: 'MESSAGE',
    pnpType: 'PRIZE',
    title: 'Two-minute free assessment',
    body:
        'Updated: Curious whether GrowERP fits how you run your business? The '
        'free assessment takes two minutes and shows your ERP fit.',
    callToAction: 'Start the free assessment',
    status: 'APPROVED',
  ),
];
