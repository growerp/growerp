import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_marketing/growerp_marketing.dart';

/// Assessment Flow Container
/// Manages the three-step assessment process and state transitions
class AssessmentFlowScreen extends StatefulWidget {
  final String assessmentId;
  final String? ownerPartyId;
  final String? campaignId;
  final VoidCallback onComplete;

  const AssessmentFlowScreen({
    Key? key,
    required this.assessmentId,
    this.ownerPartyId,
    this.campaignId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  // Respondent data collected in step 1
  late String _respondentName;
  late String _respondentEmail;
  late String _respondentCompany;
  late String _respondentPhone;

  // Answers collected in step 2
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _respondentName = '';
    _respondentEmail = '';
    _respondentCompany = '';
    _respondentPhone = '';

    // Fetch complete assessment data with questions, options, and thresholds
    context.read<AssessmentBloc>().add(
          AssessmentFetchAll(
            assessmentId: widget.assessmentId,
            ownerPartyId: widget.ownerPartyId,
          ),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _moveToNextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _moveToPreviousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _storeRespondentData({
    required String name,
    required String email,
    required String company,
    required String phone,
  }) {
    setState(() {
      _respondentName = name;
      _respondentEmail = email;
      _respondentCompany = company;
      _respondentPhone = phone;
    });
  }

  void _storeAnswers(Map<String, dynamic> answers) {
    setState(() {
      _answers.addAll(answers);
    });
  }

  void _submitAssessment() {
    // Emit submit event to BLoC
    context.read<AssessmentBloc>().add(
          AssessmentSubmit(
            assessmentId: widget.assessmentId,
            answers: _answers,
            respondentName: _respondentName,
            respondentEmail: _respondentEmail,
            respondentPhone: _respondentPhone,
            respondentCompany: _respondentCompany,
            campaignId: widget.campaignId,
          ),
        );
    // Move to results page
    _moveToNextStep();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        // Show error message if fetch fails
        if (state.status == AssessmentStatus.failure && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading assessment: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (_currentStep > 0 && !didPop) {
            _moveToPreviousStep();
          }
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentStep = index);
          },
          physics: const NeverScrollableScrollPhysics(), // Control via buttons
          children: [
            // Step 1: Lead Capture
            LeadCaptureScreen(
              onSubmit: (name, email, company, phone) {
                _storeRespondentData(
                  name: name,
                  email: email,
                  company: company,
                  phone: phone,
                );
                _moveToNextStep();
              },
            ),

            // Step 2: Assessment Questions
            BlocBuilder<AssessmentBloc, AssessmentState>(
              builder: (context, state) {
                // Handle error state first
                if (state.status == AssessmentStatus.failure) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Assessment - Step 2')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          const Text('Error loading assessment'),
                          if (state.message != null) ...[
                            const SizedBox(height: 8),
                            Text(state.message!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _moveToPreviousStep,
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Wait for assessment data to load before showing questions screen
                if (state.selectedAssessment == null ||
                    state.selectedAssessment!.questions == null ||
                    state.selectedAssessment!.questions!.isEmpty) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Assessment - Step 2')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                              'Loading assessment questions... Status: ${state.status}'),
                          if (state.message != null) ...[
                            const SizedBox(height: 8),
                            Text('Error: ${state.message}',
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                // Pass the complete assessment object with all nested data
                return AssessmentQuestionsScreen(
                  assessment: state.selectedAssessment!,
                  onAnswersCollected: _storeAnswers,
                  onNext: _submitAssessment,
                  onPrevious: _moveToPreviousStep,
                );
              },
            ),

            // Step 3: Confirmation
            AssessmentConfirmationScreen(
              email: _respondentEmail,
              assessmentName: BlocProvider.of<AssessmentBloc>(context)
                      .state
                      .selectedAssessment
                      ?.assessmentName ??
                  'Assessment',
            ),
          ],
        ),
      ),
    );
  }
}
