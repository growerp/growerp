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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA), // #667eea
              Color(0xFF764BA2), // #764ba2
            ],
          ),
        ),
        child: SafeArea(
          child: questions.isEmpty
              ? const Center(
                  child: Text(
                    'No questions available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                )
              : _buildQuestionView(context, questions),
        ),
      ),
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
                color: Colors.white.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepIndicator(2, true, 'Questions'),
            Expanded(
              child: Container(
                height: 2,
                color: Colors.white.withValues(alpha: 0.3),
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
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
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
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF667EEA)
                    : Colors.white.withValues(alpha: 0.7),
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
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion question) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText ?? 'Untitled Question',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                    fontSize: 24,
                  ),
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
    final currentAnswer =
        _answers[question.assessmentQuestionId] as String? ?? '';

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
                _answers[question.assessmentQuestionId ?? ''] = value;
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
    final selectedOptionId = _answers[question.assessmentQuestionId];

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
        final isSelected =
            selectedOptionId == option.assessmentQuestionOptionId;

        return _buildOptionTile(
          option: option,
          isSelected: isSelected,
          onTap: () => _answerQuestion(question.assessmentQuestionId ?? '',
              option.assessmentQuestionOptionId ?? ''),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF667EEA) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? const Color(0xFF667EEA).withValues(alpha: 0.1)
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF667EEA) : Colors.grey[400]!,
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF667EEA) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.optionText ?? 'Option',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF667EEA)
                          : const Color(0xFF4A5568),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final questions = widget.assessment.questions ?? [];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;

    return Wrap(
      spacing: 16,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton(
          onPressed: _previousQuestion,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Previous',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF667EEA),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLastQuestion ? 'Complete' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
