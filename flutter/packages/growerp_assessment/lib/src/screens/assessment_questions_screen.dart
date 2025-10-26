import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/assessment_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

/// Step 2: Assessment Questions Screen
/// Displays assessment questions and collects answers
class AssessmentQuestionsScreen extends StatefulWidget {
  final String assessmentId;
  final Function(Map<String, dynamic>) onAnswersCollected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const AssessmentQuestionsScreen({
    Key? key,
    required this.assessmentId,
    required this.onAnswersCollected,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<AssessmentQuestionsScreen> createState() =>
      _AssessmentQuestionsScreenState();
}

class _AssessmentQuestionsScreenState extends State<AssessmentQuestionsScreen> {
  late PageController _questionPageController;
  int _currentQuestionIndex = 0;
  final Map<String, dynamic> _answers = {};

  List<AssessmentQuestion> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _questionPageController = PageController();
    _loadQuestions();
  }

  @override
  void dispose() {
    _questionPageController.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    // Load questions from backend via BLoC
    context.read<AssessmentBloc>().add(
          AssessmentFetchQuestions(assessmentId: widget.assessmentId),
        );
  }

  void _answerQuestion(String questionId, String selectedOptionId) {
    setState(() {
      _answers[questionId] = selectedOptionId;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _questionPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit assessment
      widget.onAnswersCollected(_answers);
      widget.onNext();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _questionPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onPrevious();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        if (state.status == AssessmentStatus.success &&
            state.questions.isNotEmpty) {
          setState(() {
            _questions = state.questions;
            _isLoading = false;
          });
        } else if (state.status == AssessmentStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error loading questions: ${state.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assessment - Step 2: Questions'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questions.isEmpty
                ? _buildEmptyState(context)
                : _buildQuestionView(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No questions available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check back later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onPrevious,
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            SizedBox(height: isMobile ? 24 : 40),

            // Question pages
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: PageView(
                controller: _questionPageController,
                onPageChanged: (index) {
                  setState(() => _currentQuestionIndex = index);
                },
                children: _questions
                    .map((question) => _buildQuestionCard(question))
                    .toList(),
              ),
            ),

            SizedBox(height: isMobile ? 24 : 40),

            // Navigation buttons
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepIndicator(1, false, 'Your Info'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(2, true, 'Questions'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(3, false, 'Results'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Step 2 of 3 - Question ${_currentQuestionIndex + 1} of ${_questions.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? Colors.blue : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion question) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildOptionsView(question),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsView(AssessmentQuestion question) {
    return FutureBuilder<List<AssessmentQuestionOption>>(
      future: _loadOptions(question.questionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading options: ${snapshot.error}'),
          );
        }

        final options = snapshot.data ?? [];
        final selectedOptionId = _answers[question.questionId];

        return ListView.separated(
          itemCount: options.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedOptionId == option.optionId;

            return _buildOptionTile(
              option: option,
              isSelected: isSelected,
              onTap: () =>
                  _answerQuestion(question.questionId, option.optionId),
            );
          },
        );
      },
    );
  }

  Future<List<AssessmentQuestionOption>> _loadOptions(String questionId) async {
    // In a real implementation, fetch from repository
    // For now, return empty list
    return [];
  }

  Widget _buildOptionTile({
    required AssessmentQuestionOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Color.fromARGB(
                  (0.1 * 255).toInt(),
                  ((Colors.blue.r * 255.0).round() & 0xff),
                  ((Colors.blue.g * 255.0).round() & 0xff),
                  ((Colors.blue.b * 255.0).round() & 0xff),
                )
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.optionText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: _previousQuestion,
          child: const Text('Previous'),
        ),
        ElevatedButton.icon(
          onPressed: _nextQuestion,
          icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
          label: Text(isLastQuestion ? 'Complete' : 'Next'),
        ),
      ],
    );
  }
}
