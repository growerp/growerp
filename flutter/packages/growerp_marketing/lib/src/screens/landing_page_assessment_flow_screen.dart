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
import 'package:growerp_marketing/growerp_marketing.dart';

/// Integrated landing page to assessment flow screen
///
/// This screen manages the complete user journey:
/// 1. Display landing page (optional - skip if startAssessmentFlow=true)
/// 2. Launch assessment (includes lead capture internally)
/// 3. Show results and next steps
class LandingPageAssessmentFlowScreen extends StatefulWidget {
  const LandingPageAssessmentFlowScreen({
    super.key,
    required this.landingPageId,
    this.ownerPartyId,
    this.assessmentId,
    this.startAssessmentFlow = false,
  });

  final String landingPageId;
  final String? ownerPartyId;
  final String? assessmentId;
  final bool startAssessmentFlow;

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

    // Load the landing page data using pseudoId (tenant-unique identifier)
    context.read<LandingPageBloc>().add(
          LandingPageFetch(
            pseudoId: widget.landingPageId,
            ownerPartyId: widget.ownerPartyId,
          ),
        );

    // If direct assessment flow requested, skip landing page and go straight to assessment
    if (widget.startAssessmentFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPage(1); // Page 1: Assessment
      });
    }
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

  void _onCtaPressed() {
    // Extract assessment ID from landing page CTA if available
    final landingPageState = context.read<LandingPageBloc>().state;
    if (landingPageState.status == LandingPageStatus.success &&
        landingPageState.selectedLandingPage?.ctaAssessmentId != null) {
      setState(() {
        _assessmentId = landingPageState.selectedLandingPage!.ctaAssessmentId;
      });
      // Navigate directly to assessment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPage(
          1,
        ); // Page 1: Assessment (lead capture is inside assessment)
      });
    } else {
      // If assessment ID not available, show error or retry
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment not available for this landing page'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

          // Page 1: Assessment (includes lead capture internally)
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
            state.selectedLandingPage?.ctaAssessmentId != null) {
          setState(() {
            _assessmentId = state.selectedLandingPage!.ctaAssessmentId;
          });
        }
      },
      child: PublicLandingPageScreen(
        landingPageId: widget.landingPageId,
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
      ownerPartyId: widget.ownerPartyId,
      onComplete: () {
        // Navigate to results on assessment completion (Page 3: Results)
        _navigateToPage(3);
      },
    );
  }

  Widget _buildResultsStep() {
    return BlocBuilder<AssessmentBloc, AssessmentState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  'Assessment Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Display result summary if available
                if (state.results.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        'Your Assessment Results',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.results
                              .map(
                                (result) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Score: ${result.score?.toStringAsFixed(1) ?? '0'}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Status: ${result.leadStatus ?? 'Unknown'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      if (result.respondentCompany != null)
                                        Text(
                                          'Company: ${result.respondentCompany}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
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
          ),
        );
      },
    );
  }
}
