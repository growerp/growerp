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
    assessmentName: 'Business Readiness Assessment',
    description:
        'Comprehensive assessment to evaluate business readiness, identify challenges, and provide tailored recommendations for success.',
    status: 'Active',
  ),
  const Assessment(
    assessmentName: 'Marketing Readiness Assessment',
    description: 'Evaluate your marketing capabilities and strategies',
    status: 'Active',
  ),
  const Assessment(
    assessmentName: 'Digital Transformation Assessment',
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
