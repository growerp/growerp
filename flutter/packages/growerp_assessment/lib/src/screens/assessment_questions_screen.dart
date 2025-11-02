import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

/// Step 2: Assessment Questions Screen
/// Displays assessment questions and collects answers
/// Questions are already loaded by parent via AssessmentFetchAll
class AssessmentQuestionsScreen extends StatefulWidget {
  final Assessment assessment;
  final Function(Map<String, dynamic>) onAnswersCollected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const AssessmentQuestionsScreen({
    Key? key,
    required this.assessment,
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

  @override
  void initState() {
    super.initState();
    _questionPageController = PageController();
  }

  @override
  void dispose() {
    _questionPageController.dispose();
    super.dispose();
  }

  void _answerQuestion(String questionId, String selectedOptionId) {
    setState(() {
      _answers[questionId] = selectedOptionId;
    });
  }

  void _nextQuestion() {
    final questions = widget.assessment.questions ?? [];
    if (_currentQuestionIndex < questions.length - 1) {
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
    final questions = widget.assessment.questions ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment - Step 2: Questions'),
        elevation: 0,
      ),
      body: questions.isEmpty
          ? const Center(
              child: Text('No questions available'),
            )
          : _buildQuestionView(context, questions),
    );
  }

  Widget _buildQuestionView(
      BuildContext context, List<AssessmentQuestion> questions) {
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
                children: questions
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
    final questions = widget.assessment.questions ?? [];

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
          'Step 2 of 3 - Question ${_currentQuestionIndex + 1} of ${questions.length}',
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
              question.questionText ?? 'Untitled Question',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: question.questionType == 'OpenText'
                  ? _buildOpenTextInput(question)
                  : _buildOptionsView(question),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenTextInput(AssessmentQuestion question) {
    final currentAnswer = _answers[question.questionId] as String? ?? '';

    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: TextEditingController(text: currentAnswer),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Enter your response here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              setState(() {
                _answers[question.questionId ?? ''] = value;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          question.isRequired == true ? 'This field is required' : 'Optional',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildOptionsView(AssessmentQuestion question) {
    // Options are already nested in the question from backend response
    // Backend handles deduplication by optionId and sorts by optionSequence
    final options = question.options ?? [];
    final selectedOptionId = _answers[question.questionId];

    if (options.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 48, color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text(
              'No options available for this question',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      );
    }

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
              _answerQuestion(question.questionId ?? '', option.optionId ?? ''),
        );
      },
    );
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
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.optionText ?? 'Option',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final questions = widget.assessment.questions ?? [];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

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
