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

// Test data based on GeneralLandingPageAssessmentImport.xml

/// Landing Page test data
List<LandingPage> landingPages = [
  const LandingPage(
    title: 'Business Readiness Assessment',
    headline: 'Are you ready to unlock your business\'s full potential?',
    subheading:
        'Answer a few questions to find out why you might be facing challenges and what steps you need to take to guarantee success.',
    hookType: null,
    ctaActionType: null,
    status: 'Draft',
    privacyPolicyUrl: null,
  ),
  const LandingPage(
    title: 'Test Landing Page 2',
    headline: 'Transform Your Business Today',
    subheading: 'Discover how our solutions can help you grow',
    hookType: null,
    ctaActionType: null,
    status: 'Draft',
  ),
  const LandingPage(
    title: 'Test Landing Page 3',
    headline: 'Scale Your Operations Efficiently',
    subheading: 'Learn the best practices for business growth',
    hookType: null,
    ctaActionType: null,
    status: 'Draft',
  ),
];

/// Assessment test data
List<Assessment> assessments = [
  const Assessment(
    assessmentName: 'Assessment1',
    description:
        'Comprehensive assessment to evaluate business readiness, identify challenges, and provide tailored recommendations for success.',
    status: 'Active',
  ),
  const Assessment(
    assessmentName: 'Assessment2',
    description: 'Evaluate your marketing capabilities and strategies',
    status: 'Active',
  ),
  const Assessment(
    assessmentName: 'Assessment3',
    description: 'Assess your digital maturity and transformation readiness',
    status: 'Draft',
  ),
];

/// Updated landing pages for testing
List<LandingPage> updatedLandingPages = [
  const LandingPage(
    title: 'Updated Business Readiness Assessment',
    headline: 'Ready to transform your business operations?',
    subheading:
        'Take our comprehensive assessment to identify growth opportunities',
    hookType: null,
    ctaActionType: 'Assessment',
    status: 'Active',
    privacyPolicyUrl: 'https://www.growerp.com/privacy-updated',
  ),
  const LandingPage(
    title: 'Updated Test Landing Page 2',
    headline: 'Revolutionize Your Business Operations',
    subheading: 'New improved solutions for exponential growth',
    hookType: null,
    ctaActionType: 'Url',
    status: 'Active',
  ),
  const LandingPage(
    title: 'Updated Test Landing Page 3',
    headline: 'Master Business Scaling Techniques',
    subheading: 'Advanced strategies for sustainable expansion',
    hookType: null,
    ctaActionType: 'Assessment',
    status: 'Active',
  ),
];

/// Landing page section fixtures used by landing page integration tests
const List<LandingPageSection> landingPageSections = [
  LandingPageSection(
    sectionTitle: 'Hero Banner',
    sectionDescription: 'Instantly show the main value proposition.',
    sectionImageUrl: 'https://cdn.growerp.com/images/hero-banner.png',
    sectionSequence: 1,
  ),
  LandingPageSection(
    sectionTitle: 'Pain Points',
    sectionDescription: 'Highlight the top challenges customers face.',
    sectionImageUrl: 'https://cdn.growerp.com/images/pain-points.png',
    sectionSequence: 2,
  ),
  LandingPageSection(
    sectionTitle: 'Solution Overview',
    sectionDescription: 'Explain how GrowERP removes the friction.',
    sectionImageUrl: 'https://cdn.growerp.com/images/solution.png',
    sectionSequence: 3,
  ),
];

/// Updated sections fixtures for edit scenarios
const List<LandingPageSection> updatedLandingPageSections = [
  LandingPageSection(
    sectionTitle: 'New Hero Banner',
    sectionDescription: 'Refined pitch targeting scale ups.',
    sectionImageUrl: 'https://cdn.growerp.com/images/hero-banner-updated.png',
    sectionSequence: 1,
  ),
  LandingPageSection(
    sectionTitle: 'Key Outcomes',
    sectionDescription: 'Summarize measurable results in three bullets.',
    sectionImageUrl: 'https://cdn.growerp.com/images/outcomes.png',
    sectionSequence: 2,
  ),
  LandingPageSection(
    sectionTitle: 'Customer Stories',
    sectionDescription: 'Share brief testimonials to build trust.',
    sectionImageUrl: 'https://cdn.growerp.com/images/testimonials.png',
    sectionSequence: 3,
  ),
];

/// Credibility statistics fixtures bundled with credibility info
const List<CredibilityStatistic> credibilityStatistics = [
  CredibilityStatistic(
    statistic: '120+ Successful Implementations',
    sequence: 1,
  ),
  CredibilityStatistic(
    statistic: 'Global team across 5 continents',
    sequence: 2,
  ),
];

/// Updated credibility statistics fixtures
const List<CredibilityStatistic> updatedCredibilityStatistics = [
  CredibilityStatistic(
    statistic: '200+ Cloud Deployments',
    sequence: 1,
  ),
  CredibilityStatistic(
    statistic: 'Customer CSAT 4.9/5',
    sequence: 2,
  ),
];

/// Credibility info fixture with default statistics
const CredibilityInfo credibilityInfo = CredibilityInfo(
  creatorBio: 'Built by ex-ERP consultants with 15+ years experience.',
  backgroundText: 'We helped SMBs on 3 continents streamline operations.',
  creatorImageUrl: 'https://www.growerp.com/getImage/obsidian/growerp.png',
  statistics: credibilityStatistics,
);

/// Updated credibility info fixture
const CredibilityInfo updatedCredibilityInfo = CredibilityInfo(
  creatorBio: 'Led by certified ERP architects and AI specialists.',
  backgroundText: 'Trusted by fintech, healthcare, and hospitality scaleups.',
  creatorImageUrl: 'https://www.growerp.com/getLogo',
  statistics: updatedCredibilityStatistics,
);

/// Updated assessments for testing
List<Assessment> updatedAssessments = [
  const Assessment(
    assessmentName: 'Updated Business Readiness Assessment',
    description:
        'Enhanced comprehensive assessment with additional metrics and insights',
    status: 'Active',
  ),
  const Assessment(
    assessmentName: 'Updated Marketing Readiness Assessment',
    description: 'Enhanced marketing evaluation with new criteria',
    status: 'Active',
  ),
  const Assessment(
    assessmentName: 'Updated Digital Transformation Assessment',
    description: 'Comprehensive digital maturity assessment',
    status: 'Active',
  ),
];

/// Assessment questions test data
/// Based on GeneralLandingPageAssessmentImport.xml
List<AssessmentQuestion> assessmentQuestions = [
  // Question 1: Multiple Choice (radio) with options
  const AssessmentQuestion(
    questionText: 'Which best describes your current situation?',
    questionDescription: 'Identify your current business state',
    questionType: 'radio',
    questionSequence: 1,
    isRequired: true,
    options: [
      AssessmentQuestionOption(
        optionText: 'Stagnant (No growth or declining)',
        optionScore: 20,
        optionSequence: 1,
      ),
      AssessmentQuestionOption(
        optionText: 'Slow Growth (1-10% annually)',
        optionScore: 50,
        optionSequence: 2,
      ),
      AssessmentQuestionOption(
        optionText: 'Rapid Growth (10%+ annually)',
        optionScore: 80,
        optionSequence: 3,
      ),
    ],
  ),
  // Question 2: Text input
  const AssessmentQuestion(
    questionText:
        'Is there anything else that you think we need to know about?',
    questionDescription:
        'Open box for relevant information (budget constraints, urgency, specific needs)',
    questionType: 'text',
    questionSequence: 2,
    isRequired: false,
  ),
];

/// Marketing Persona test data
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
