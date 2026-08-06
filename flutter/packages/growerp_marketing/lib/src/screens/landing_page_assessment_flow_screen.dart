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
    this.campaignId,
    this.startAssessmentFlow = false,
  });

  final String landingPageId;
  final String? ownerPartyId;
  final String? assessmentId;
  final String? campaignId;
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
        SnackBar(
          content: Text(MarketingLocalizations.of(context)!.assessmentNotAvailableForThisLandingPage),
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
          _buildAssessmentStep(),

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
          if (widget.startAssessmentFlow) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPage(1);
            });
          }
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
      return const Center(child: CircularProgressIndicator());
    }

    return AssessmentFlowScreen(
      assessmentId: _assessmentId!,
      ownerPartyId: widget.ownerPartyId,
      campaignId: widget.campaignId,
      onComplete: () {
        _navigateToPage(2);
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
                      child: Text(MarketingLocalizations.of(context)!.backToLandingPage),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to detailed results dashboard
                        Navigator.of(context).pop();
                      },
                      child: Text(MarketingLocalizations.of(context)!.viewDetailedResults),
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
