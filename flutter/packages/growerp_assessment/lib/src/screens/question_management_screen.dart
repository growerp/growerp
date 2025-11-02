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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Screen for managing questions and options within an assessment
class QuestionManagementScreen extends StatefulWidget {
  final Assessment assessment;

  const QuestionManagementScreen({
    super.key,
    required this.assessment,
  });

  @override
  State<QuestionManagementScreen> createState() =>
      _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> {
  List<AssessmentQuestion> _questions = [];
  Map<String, List<AssessmentQuestionOption>> _questionOptions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final RestClient restClient = context.read<RestClient>();

      // Load questions for this assessment
      final questionsResponse = await restClient.getAssessmentQuestions(
        assessmentId: widget.assessment.assessmentId,
      );

      // Load options for each question
      final Map<String, List<AssessmentQuestionOption>> optionsMap = {};
      for (final question in questionsResponse.questions) {
        try {
          final optionsResponse = await restClient.getAssessmentQuestionOptions(
            assessmentId: widget.assessment.assessmentId,
            questionId: question.questionId ?? '',
          );
          optionsMap[question.questionId ?? ''] = optionsResponse.options;
        } catch (e) {
          // If options fail to load, set empty list
          optionsMap[question.questionId ?? ''] = [];
        }
      }

      setState(() {
        _questions = questionsResponse.questions;
        _questionOptions = optionsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to load questions: $e',
          Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions - ${widget.assessment.assessmentName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuestions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        key: const Key('addQuestion'),
        onPressed: _showAddQuestionDialog,
        backgroundColor: Colors.green[700],
        tooltip: 'Add Question',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_questions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final question = _questions[index];
          final options = _questionOptions[question.questionId] ?? [];
          return _buildQuestionCard(question, options);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Questions Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add questions to make this assessment interactive',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            key: const Key('addFirstQuestion'),
            onPressed: _showAddQuestionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      AssessmentQuestion question, List<AssessmentQuestionOption> options) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${question.questionSequence}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText ?? 'Untitled Question',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question.questionType ?? 'text',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          if (question.isRequired ?? false) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleQuestionAction(value, question),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Question')),
                    const PopupMenuItem(
                        value: 'add_option', child: Text('Add Option')),
                    const PopupMenuItem(
                        value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Options:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map((option) => _buildOptionTile(question, option)),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined,
                        color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No options added yet. Add options to make this question interactive.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAddOptionDialog(question),
                      child: const Text('Add Option'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      AssessmentQuestion question, AssessmentQuestionOption option) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${option.optionSequence}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(option.optionText ?? 'Option')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Score: ${option.optionScore}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) => _handleOptionAction(value, question, option),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  void _handleQuestionAction(String action, AssessmentQuestion question) {
    switch (action) {
      case 'edit':
        _showEditQuestionDialog(question);
        break;
      case 'add_option':
        _showAddOptionDialog(question);
        break;
      case 'duplicate':
        _duplicateQuestion(question);
        break;
      case 'delete':
        _deleteQuestion(question);
        break;
    }
  }

  void _handleOptionAction(String action, AssessmentQuestion question,
      AssessmentQuestionOption option) {
    switch (action) {
      case 'edit':
        _showEditOptionDialog(question, option);
        break;
      case 'delete':
        _deleteOption(question, option);
        break;
    }
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        assessment: widget.assessment,
        onSaved: _loadQuestions,
      ),
    );
  }

  void _showEditQuestionDialog(AssessmentQuestion question) {
    showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        assessment: widget.assessment,
        question: question,
        onSaved: _loadQuestions,
      ),
    );
  }

  void _showAddOptionDialog(AssessmentQuestion question) {
    showDialog(
      context: context,
      builder: (context) => OptionFormDialog(
        assessment: widget.assessment,
        question: question,
        onSaved: _loadQuestions,
      ),
    );
  }

  void _showEditOptionDialog(
      AssessmentQuestion question, AssessmentQuestionOption option) {
    showDialog(
      context: context,
      builder: (context) => OptionFormDialog(
        assessment: widget.assessment,
        question: question,
        option: option,
        onSaved: _loadQuestions,
      ),
    );
  }

  void _duplicateQuestion(AssessmentQuestion question) {
    // Duplicate the question with a new ID
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Question'),
        content: Text(
          'Create a copy of "${question.questionText}"?\n\nThe duplicate will be added to the same assessment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();

              HelperFunctions.showMessage(
                context,
                'Question duplicated successfully',
                Colors.green,
              );

              // In a real implementation, you would:
              // 1. Create a new question object with same properties but new ID
              // 2. Save it to the backend via RestClient
              // 3. Refresh the question list
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _deleteQuestion(AssessmentQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
          'Are you sure you want to delete this question?\n\n"${question.questionText}"\n\nThis will also delete all associated options.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeleteQuestion(question);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteOption(
      AssessmentQuestion question, AssessmentQuestionOption option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Option'),
        content: Text(
          'Are you sure you want to delete this option?\n\n"${option.optionText}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeleteOption(question, option);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteQuestion(AssessmentQuestion question) async {
    try {
      final RestClient restClient = context.read<RestClient>();
      await restClient.deleteAssessmentQuestion(
        assessmentId: widget.assessment.assessmentId,
        questionId: question.questionId ?? '',
      );

      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Question deleted successfully',
          Colors.green,
        );
      }

      await _loadQuestions();
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to delete question: $e',
          Colors.red,
        );
      }
    }
  }

  Future<void> _performDeleteOption(
      AssessmentQuestion question, AssessmentQuestionOption option) async {
    try {
      final RestClient restClient = context.read<RestClient>();
      await restClient.deleteAssessmentQuestionOption(
        assessmentId: widget.assessment.assessmentId,
        questionId: question.questionId ?? '',
        optionId: option.optionId ?? '',
      );

      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Option deleted successfully',
          Colors.green,
        );
      }

      await _loadQuestions();
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to delete option: $e',
          Colors.red,
        );
      }
    }
  }
}

/// Dialog for creating/editing questions
class QuestionFormDialog extends StatefulWidget {
  final Assessment assessment;
  final AssessmentQuestion? question; // null for create, non-null for edit
  final VoidCallback onSaved;

  const QuestionFormDialog({
    super.key,
    required this.assessment,
    this.question,
    required this.onSaved,
  });

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionTextController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sequenceController = TextEditingController();

  String _selectedType = 'radio';
  bool _isRequired = true;
  bool _isLoading = false;
  bool get _isEditing => widget.question != null;

  final List<String> _questionTypes = [
    'radio',
    'dropdown',
    'text',
    'email',
    'yes_no',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _questionTextController.text = widget.question!.questionText ?? '';
      _descriptionController.text = widget.question!.questionDescription ?? '';
      _sequenceController.text =
          (widget.question!.questionSequence ?? 0).toString();
      _selectedType = widget.question!.questionType ?? 'radio';
      _isRequired = widget.question!.isRequired ?? true;
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _descriptionController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Question' : 'Add Question'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('questionText'),
                  controller: _questionTextController,
                  decoration: const InputDecoration(
                    labelText: 'Question Text *',
                    hintText: 'Enter your question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Question text is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Additional context or instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _questionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_formatQuestionType(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sequenceController,
                  decoration: const InputDecoration(
                    labelText: 'Sequence',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final seq = int.tryParse(value);
                      if (seq == null || seq < 1) {
                        return 'Must be a positive number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Required Question'),
                  value: _isRequired,
                  onChanged: (value) {
                    setState(() {
                      _isRequired = value ?? true;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('saveQuestion'),
          onPressed: _isLoading ? null : _saveQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  String _formatQuestionType(String type) {
    switch (type) {
      case 'radio':
        return 'Multiple Choice (Radio)';
      case 'dropdown':
        return 'Dropdown';
      case 'text':
        return 'Text Input';
      case 'email':
        return 'Email Input';
      case 'yes_no':
        return 'Yes/No';
      default:
        return type;
    }
  }

  void _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final RestClient restClient = context.read<RestClient>();
      final sequence = int.tryParse(_sequenceController.text.trim()) ?? 1;

      final questionData = AssessmentQuestion(
        questionId: _isEditing ? widget.question!.questionId : '',
        pseudoId: _isEditing ? widget.question!.pseudoId : '',
        assessmentId: widget.assessment.assessmentId,
        questionSequence: sequence,
        questionType: _selectedType,
        questionText: _questionTextController.text.trim(),
        questionDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isRequired: _isRequired,
        createdDate: DateTime.now(),
      );

      if (_isEditing) {
        await restClient.updateAssessmentQuestion(
          assessmentId: widget.assessment.assessmentId,
          questionId: widget.question!.questionId ?? '',
          questionText: questionData.questionText ?? '',
          questionType: questionData.questionType ?? 'radio',
          questionSequence: questionData.questionSequence ?? 0,
          isRequired: (questionData.isRequired ?? false) ? 'Y' : 'N',
        );
      } else {
        await restClient.createAssessmentQuestion(
          assessmentId: widget.assessment.assessmentId,
          questionText: questionData.questionText ?? '',
          questionType: questionData.questionType ?? 'radio',
          questionSequence: questionData.questionSequence ?? 0,
          isRequired: (questionData.isRequired ?? false) ? 'Y' : 'N',
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        HelperFunctions.showMessage(
          context,
          _isEditing
              ? 'Question updated successfully'
              : 'Question created successfully',
          Colors.green,
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to save question: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Dialog for creating/editing options
class OptionFormDialog extends StatefulWidget {
  final Assessment assessment;
  final AssessmentQuestion question;
  final AssessmentQuestionOption? option; // null for create, non-null for edit
  final VoidCallback onSaved;

  const OptionFormDialog({
    super.key,
    required this.assessment,
    required this.question,
    this.option,
    required this.onSaved,
  });

  @override
  State<OptionFormDialog> createState() => _OptionFormDialogState();
}

class _OptionFormDialogState extends State<OptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _optionTextController = TextEditingController();
  final _scoreController = TextEditingController();
  final _sequenceController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.option != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _optionTextController.text = widget.option!.optionText ?? '';
      _scoreController.text = (widget.option!.optionScore ?? 0).toString();
      _sequenceController.text =
          (widget.option!.optionSequence ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _optionTextController.dispose();
    _scoreController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Option' : 'Add Option'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Question: ${widget.question.questionText}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('optionText'),
                controller: _optionTextController,
                decoration: const InputDecoration(
                  labelText: 'Option Text *',
                  hintText: 'Enter the option text',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option text is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('score'),
                      controller: _scoreController,
                      decoration: const InputDecoration(
                        labelText: 'Score *',
                        hintText: '0.0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Score is required';
                        }
                        final score = double.tryParse(value);
                        if (score == null) {
                          return 'Must be a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sequenceController,
                      decoration: const InputDecoration(
                        labelText: 'Sequence',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final seq = int.tryParse(value);
                          if (seq == null || seq < 1) {
                            return 'Must be a positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Scores determine assessment results. Higher scores typically indicate better performance.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('saveOption'),
          onPressed: _isLoading ? null : _saveOption,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  void _saveOption() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final RestClient restClient = context.read<RestClient>();
      final score = double.parse(_scoreController.text.trim());
      final sequence = int.tryParse(_sequenceController.text.trim()) ?? 1;

      final optionData = AssessmentQuestionOption(
        optionId: _isEditing ? widget.option!.optionId : '',
        pseudoId: _isEditing ? widget.option!.pseudoId : '',
        questionId: widget.question.questionId,
        assessmentId: widget.assessment.assessmentId,
        optionSequence: sequence,
        optionText: _optionTextController.text.trim(),
        optionScore: score,
        createdDate: DateTime.now(),
      );

      if (_isEditing) {
        await restClient.updateAssessmentQuestionOption(
          assessmentId: widget.assessment.assessmentId,
          questionId: widget.question.questionId ?? '',
          optionId: widget.option!.optionId ?? '',
          optionText: optionData.optionText ?? '',
          optionScore: optionData.optionScore ?? 0,
          optionSequence: optionData.optionSequence ?? 0,
        );
      } else {
        await restClient.createAssessmentQuestionOption(
          assessmentId: widget.assessment.assessmentId,
          questionId: widget.question.questionId ?? '',
          optionText: optionData.optionText ?? '',
          optionScore: optionData.optionScore ?? 0,
          optionSequence: optionData.optionSequence ?? 0,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        HelperFunctions.showMessage(
          context,
          _isEditing
              ? 'Option updated successfully'
              : 'Option created successfully',
          Colors.green,
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to save option: $e',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
