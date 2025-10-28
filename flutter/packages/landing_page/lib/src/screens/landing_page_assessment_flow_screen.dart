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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import 'public_landing_page_screen.dart';

/// Integrated landing page to assessment flow screen
///
/// This screen manages the complete user journey:
/// 1. Display landing page
/// 2. Capture lead information on CTA click
/// 3. Launch assessment
/// 4. Show results and next steps
class LandingPageAssessmentFlowScreen extends StatefulWidget {
  const LandingPageAssessmentFlowScreen({
    super.key,
    required this.pageId,
    this.ownerPartyId,
    this.assessmentId,
  });

  final String pageId;
  final String? ownerPartyId;
  final String? assessmentId;

  @override
  State<LandingPageAssessmentFlowScreen> createState() =>
      _LandingPageAssessmentFlowScreenState();
}

class _LandingPageAssessmentFlowScreenState
    extends State<LandingPageAssessmentFlowScreen> {
  final PageController _pageController = PageController();
  String? _assessmentId;

  @override
  void initState() {
    super.initState();
    _assessmentId = widget.assessmentId;

    // Load the landing page data
    context.read<LandingPageBloc>().add(
      LandingPageFetch(widget.pageId, ownerPartyId: widget.ownerPartyId),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onCtaPressed(CallToAction cta) {
    // Extract assessment ID from landing page if available
    final landingPageState = context.read<LandingPageBloc>().state;
    if (landingPageState.status == LandingPageStatus.success &&
        landingPageState.selectedLandingPage?.assessmentId != null) {
      _assessmentId = landingPageState.selectedLandingPage!.assessmentId;
    }

    // Skip lead capture (already collected by landing page) and go directly to assessment
    _navigateToPage(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe navigation
        children: [
          // Page 0: Landing Page
          _buildLandingPageStep(),

          // Page 1: Assessment (skipped lead capture - already collected by landing page)
          if (_assessmentId != null) _buildAssessmentStep(),

          // Page 2: Results & Next Steps
          _buildResultsStep(),
        ],
      ),
    );
  }

  Widget _buildLandingPageStep() {
    return BlocListener<LandingPageBloc, LandingPageState>(
      listener: (context, state) {
        if (state.status == LandingPageStatus.success &&
            state.selectedLandingPage?.assessmentId != null) {
          setState(() {
            _assessmentId = state.selectedLandingPage!.assessmentId;
          });
        }
      },
      child: PublicLandingPageScreen(
        pageId: widget.pageId,
        ownerPartyId: widget.ownerPartyId,
        onCtaPressed: _onCtaPressed,
      ),
    );
  }

  Widget _buildAssessmentStep() {
    if (_assessmentId == null) {
      return const Center(child: Text('Assessment not available'));
    }

    return AssessmentFlowScreen(
      assessmentId: _assessmentId!,
      onComplete: () {
        // Navigate to results on assessment completion
        _navigateToPage(2);
      },
    );
  }

  Widget _buildResultsStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Assessment Complete!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you for completing the assessment. Your results have been processed and you should receive them shortly.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _navigateToPage(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Back to Landing Page'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to detailed results dashboard
                  Navigator.of(context).pop();
                },
                child: const Text('View Detailed Results'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
