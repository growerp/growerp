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

import '../bloc/question_bloc.dart';
import '../bloc/question_event.dart';
import '../bloc/question_state.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String assessmentId;
  final AssessmentQuestion question;

  const QuestionDetailScreen({
    super.key,
    required this.assessmentId,
    required this.question,
  });

  @override
  QuestionDetailScreenState createState() => QuestionDetailScreenState();
}

class QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionTextController;
  late TextEditingController _questionDescriptionController;
  late String _questionType;
  late bool _isRequired;
  late List<Map<String, dynamic>> _options;
  bool _isSubmitting = false;

  final List<String> _questionTypes = [
    'text',
    'email',
    'radio',
  ];

  @override
  void initState() {
    super.initState();
    _questionTextController =
        TextEditingController(text: widget.question.questionText ?? '');
    _questionDescriptionController =
        TextEditingController(text: widget.question.questionDescription ?? '');

    // Ensure question type is in the list, default to 'text' if not
    final incomingType = widget.question.questionType ?? 'text';
    _questionType =
        _questionTypes.contains(incomingType) ? incomingType : 'text';

    _isRequired = widget.question.isRequired ?? false;

    // Initialize options list with existing data
    _options = (widget.question.options ?? [])
        .map((opt) => {
              'id': opt.assessmentQuestionOptionId,
              'textController':
                  TextEditingController(text: opt.optionText ?? ''),
              'scoreController': TextEditingController(
                  text: opt.optionScore?.toString() ?? '0'),
              'sequence': opt.optionSequence ?? 0,
            })
        .toList();
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _questionDescriptionController.dispose();
    for (var opt in _options) {
      (opt['textController'] as TextEditingController).dispose();
      (opt['scoreController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({
        'id': null,
        'textController': TextEditingController(),
        'scoreController': TextEditingController(text: '0'),
        'sequence': _options.length + 1,
      });
    });
  }

  void _removeOption(int index) {
    setState(() {
      ((_options[index]['textController']) as TextEditingController).dispose();
      ((_options[index]['scoreController']) as TextEditingController).dispose();
      _options.removeAt(index);
      // Update sequences
      for (int i = 0; i < _options.length; i++) {
        _options[i]['sequence'] = i + 1;
      }
    });
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final isNew = widget.question.assessmentQuestionId == null ||
        widget.question.assessmentQuestionId!.isEmpty;
    final questionBloc = context.read<QuestionBloc>();

    // Convert options to AssessmentQuestionOption objects
    final optionsList = _options.map((opt) {
      final scoreText = (opt['scoreController'] as TextEditingController).text;
      final score = double.tryParse(scoreText) ?? 0.0;

      return AssessmentQuestionOption(
        assessmentQuestionOptionId: opt['id'],
        assessmentId: widget.assessmentId,
        optionText: (opt['textController'] as TextEditingController).text,
        optionScore: score,
        optionSequence: opt['sequence'] as int,
      );
    }).toList();

    if (isNew) {
      questionBloc.add(
        QuestionCreate(
          assessmentId: widget.assessmentId,
          questionText: _questionTextController.text,
          questionType: _questionType,
          questionSequence: widget.question.questionSequence,
          isRequired: _isRequired,
          options: optionsList,
        ),
      );
    } else {
      questionBloc.add(
        QuestionUpdate(
          assessmentId: widget.assessmentId,
          questionId: widget.question.assessmentQuestionId!,
          questionText: _questionTextController.text,
          questionDescription: _questionDescriptionController.text,
          questionType: _questionType,
          questionSequence: widget.question.questionSequence,
          isRequired: _isRequired,
          options: optionsList,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.question.assessmentQuestionId == null ||
        widget.question.assessmentQuestionId!.isEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: popUp(
        context: context,
        title: isNew ? 'New Question' : 'Edit Question',
        width: 700,
        height: 700,
        child: BlocConsumer<QuestionBloc, QuestionState>(
          listener: (context, state) {
            if (state.status == QuestionStatus.failure) {
              setState(() {
                _isSubmitting = false;
              });
              HelperFunctions.showMessage(
                context,
                state.message ?? 'Error',
                Colors.red,
              );
            }
            if (state.status == QuestionStatus.success && _isSubmitting) {
              // Close dialog only when user explicitly saves
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state.status == QuestionStatus.loading) {
              return const LoadingIndicator();
            }

            return SingleChildScrollView(
              key: const Key('questionDetailListView'),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Text
                    TextFormField(
                      key: const Key('questionText'),
                      controller: _questionTextController,
                      decoration: const InputDecoration(
                        labelText: 'Question Text *',
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter question text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Question Description
                    TextFormField(
                      key: const Key('questionDescription'),
                      controller: _questionDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Question Type Dropdown
                    DropdownButtonFormField<String>(
                      key: const Key('questionType'),
                      initialValue: _questionType,
                      decoration: const InputDecoration(
                        labelText: 'Question Type',
                      ),
                      items: _questionTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _questionType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Is Required Checkbox
                    CheckboxListTile(
                      key: const Key('isRequired'),
                      title: const Text('Required Question'),
                      value: _isRequired,
                      onChanged: (value) {
                        setState(() {
                          _isRequired = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Options Section - only show for question types that need options
                    if (_questionType != 'text' &&
                        _questionType != 'email') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Answer Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            key: const Key('addOption'),
                            onPressed: _addOption,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Option'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add answer choices with scores for assessment scoring',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Options List
                      if (_options.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No options yet. Add options for multiple choice questions.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ..._options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final opt = entry.value;
                          // Use unique ID if available, otherwise generate from index
                          final uniqueId = opt['id'] ?? 'new_$index';
                          return Card(
                            key: Key(uniqueId),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Option number badge
                                  CircleAvatar(
                                    radius: 16,
                                    child: Text('${index + 1}'),
                                  ),
                                  const SizedBox(width: 12),
                                  // Option text field
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: Key('${uniqueId}_text'),
                                      controller: opt['textController']
                                          as TextEditingController,
                                      decoration: const InputDecoration(
                                        labelText: 'Option Text',
                                        isDense: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Score field
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      key: Key('${uniqueId}_score'),
                                      controller: opt['scoreController']
                                          as TextEditingController,
                                      decoration: const InputDecoration(
                                        labelText: 'Score',
                                        isDense: true,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeOption(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    Center(
                      child: ElevatedButton(
                        key: const Key('save'),
                        onPressed: _saveQuestion,
                        child: Text(isNew ? 'Create' : 'Update'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
