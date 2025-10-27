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
  User? _capturedLead;
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

    // Navigate to lead capture
    _navigateToPage(1);
  }

  void _onLeadCaptured(User lead) {
    setState(() {
      _capturedLead = lead;
    });

    // Navigate to assessment
    _navigateToPage(2);
  }

  void _goBackToLandingPage() {
    _navigateToPage(0);
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

          // Page 1: Lead Capture
          _buildLeadCaptureStep(),

          // Page 2: Assessment
          if (_assessmentId != null && _capturedLead != null)
            _buildAssessmentStep(),

          // Page 3: Results & Next Steps
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

  Widget _buildLeadCaptureStep() {
    return _CustomLeadCaptureWidget(
      onLeadCaptured: _onLeadCaptured,
      onBack: _goBackToLandingPage,
    );
  }

  Widget _buildAssessmentStep() {
    if (_assessmentId == null || _capturedLead == null) {
      return const Center(child: Text('Assessment not available'));
    }

    return AssessmentFlowScreen(
      assessmentId: _assessmentId!,
      onComplete: () {
        // Navigate to results on assessment completion
        _navigateToPage(3);
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
                onPressed: _goBackToLandingPage,
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

/// Custom lead capture widget for the landing page flow
class _CustomLeadCaptureWidget extends StatefulWidget {
  const _CustomLeadCaptureWidget({
    required this.onLeadCaptured,
    required this.onBack,
  });

  final Function(User) onLeadCaptured;
  final VoidCallback onBack;

  @override
  State<_CustomLeadCaptureWidget> createState() =>
      _CustomLeadCaptureWidgetState();
}

class _CustomLeadCaptureWidgetState extends State<_CustomLeadCaptureWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a User object from the form data
      final user = User(
        partyId: 'lead-${DateTime.now().millisecondsSinceEpoch}',
        pseudoId: 'lead-${DateTime.now().millisecondsSinceEpoch}',
        loginName: _emailController.text.trim(),
        firstName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        telephoneNr: _phoneController.text.trim(),
        company: Company(
          partyId: 'company-${DateTime.now().millisecondsSinceEpoch}',
          pseudoId: 'company-${DateTime.now().millisecondsSinceEpoch}',
          name: _companyController.text.trim(),
        ),
      );

      widget.onLeadCaptured(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Before we begin...'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Please provide your information to receive personalized results',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue to Assessment',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Your information will be used to personalize your assessment results and provide you with relevant recommendations.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
