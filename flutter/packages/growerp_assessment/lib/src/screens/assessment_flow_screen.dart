import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/assessment_bloc.dart';
import 'lead_capture_screen.dart';
import 'assessment_questions_screen.dart';
import 'assessment_results_screen.dart';

/// Assessment Flow Container
/// Manages the three-step assessment process and state transitions
class AssessmentFlowScreen extends StatefulWidget {
  final String assessmentId;
  final VoidCallback onComplete;

  const AssessmentFlowScreen({
    Key? key,
    required this.assessmentId,
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
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _moveToPreviousStep();
          return false;
        }
        return true;
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
            assessmentId: widget.assessmentId,
            onRespondentDataCollected: _storeRespondentData,
            onNext: _moveToNextStep,
          ),

          // Step 2: Assessment Questions
          AssessmentQuestionsScreen(
            assessmentId: widget.assessmentId,
            onAnswersCollected: _storeAnswers,
            onNext: _submitAssessment,
            onPrevious: _moveToPreviousStep,
          ),

          // Step 3: Results
          AssessmentResultsScreen(
            assessmentId: widget.assessmentId,
            respondentName: _respondentName,
            onComplete: widget.onComplete,
          ),
        ],
      ),
    );
  }
}
