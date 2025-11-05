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
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/assessment_bloc.dart';
import '../bloc/question_bloc.dart';
import 'question_list.dart';

class AssessmentDetailScreen extends StatefulWidget {
  final Assessment assessment;

  const AssessmentDetailScreen({
    super.key,
    required this.assessment,
  });

  @override
  AssessmentDetailScreenState createState() => AssessmentDetailScreenState();
}

class AssessmentDetailScreenState extends State<AssessmentDetailScreen> {
  late ScrollController _scrollController;
  late bool isPhone;
  late double top;
  double? right;
  late bool isVisible;

  // Form controllers
  late TextEditingController _pseudoIdController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late String _selectedStatus;
  late Assessment updatedAssessment;
  late AssessmentBloc _assessmentBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    top = 100;
    isVisible = true;

    // Initialize form controllers
    _pseudoIdController =
        TextEditingController(text: widget.assessment.pseudoId);
    _nameController =
        TextEditingController(text: widget.assessment.assessmentName);
    _descriptionController =
        TextEditingController(text: widget.assessment.description ?? '');

    _selectedStatus = widget.assessment.status.toUpperCase();
    updatedAssessment = widget.assessment;
    _assessmentBloc = context.read<AssessmentBloc>();

    _scrollController.addListener(() {
      if (isVisible &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        if (mounted) {
          setState(() {
            isVisible = false;
          });
        }
      }
      if (!isVisible &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        if (mounted) {
          setState(() {
            isVisible = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 40);

    return Dialog(
      key: Key('AssessmentDetail${widget.assessment.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: "Assessment #${widget.assessment.pseudoId}",
        width: isPhone ? 400 : 900,
        height: isPhone ? 700 : 600,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: isPhone ? null : _updateButton(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            body: Stack(
              children: [
                BlocConsumer<AssessmentBloc, AssessmentState>(
                  listener: (context, state) {
                    if (state.status == AssessmentStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Error',
                        Colors.red,
                      );
                    }
                    if (state.status == AssessmentStatus.success) {
                      Navigator.of(context).pop(
                        state.selectedAssessment,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.status == AssessmentStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return _buildContent();
                  },
                ),
                Positioned(
                  right: right,
                  top: top,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        top += details.delta.dy;
                        right = right! - details.delta.dx;
                      });
                    },
                    child: Column(
                      children: [
                        FloatingActionButton(
                          key: const Key("questions"),
                          tooltip: 'Questions',
                          heroTag: "questions",
                          backgroundColor: widget.assessment.assessmentId == 'unknown' ? Colors.grey : null,
                          onPressed: widget.assessment.assessmentId == 'unknown'
                              ? () {
                                  HelperFunctions.showMessage(
                                    context,
                                    'Please save the assessment first',
                                    Colors.orange,
                                  );
                                }
                              : () async => await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: popUp(
                                          context: context,
                                          title: 'Questions',
                                          height: 600,
                                          width: 400,
                                          child: _buildQuestionsPlaceholder(),
                                        ),
                                      );
                                    },
                                  ),
                          child: const Icon(Icons.quiz),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          key: const Key("deleteAssessment"),
                          tooltip: 'Delete Assessment',
                          heroTag: "deleteAssessment",
                          backgroundColor: Colors.red,
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Assessment'),
                                  content: const Text(
                                    'Are you sure you want to delete this assessment?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmed == true && mounted) {
                              _assessmentBloc.add(
                                AssessmentDelete(widget.assessment),
                              );
                            }
                          },
                          child: const Icon(Icons.delete),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('assessmentDetailListView'),
        child: Column(
          children: [
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Assessment Information',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('id'),
                          decoration: const InputDecoration(labelText: 'ID'),
                          controller: _pseudoIdController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'ID is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('status'),
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          hint: const Text('Select status'),
                          initialValue: _selectedStatus,
                          items: ['DRAFT', 'ACTIVE', 'INACTIVE'].map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStatus = newValue ?? 'DRAFT';
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('name'),
                          decoration: const InputDecoration(labelText: 'Name'),
                          controller: _nameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('description'),
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          controller: _descriptionController,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (ResponsiveBreakpoints.of(context).isMobile)
              const SizedBox(height: 20),
            if (ResponsiveBreakpoints.of(context).isMobile) _updateButton(),
            if (ResponsiveBreakpoints.of(context).isMobile)
              const SizedBox(height: 20),
            if (ResponsiveBreakpoints.of(context).isMobile) _buildMobileActionButtons(),
            if (ResponsiveBreakpoints.of(context).isMobile)
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: OutlinedButton.icon(
        key: const Key("mobileQuestions"),
        icon: const Icon(Icons.quiz),
        label: const Text('Questions'),
        style: widget.assessment.assessmentId == 'unknown'
            ? OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
              )
            : null,
        onPressed: widget.assessment.assessmentId == 'unknown'
            ? () {
                HelperFunctions.showMessage(
                  context,
                  'Please save the assessment first',
                  Colors.orange,
                );
              }
            : () async => await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: popUp(
                        context: context,
                        title: 'Questions',
                        height: 600,
                        width: 400,
                        child: _buildQuestionsPlaceholder(),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildQuestionsPlaceholder() {
    return BlocProvider.value(
      value: context.read<QuestionBloc>(),
      child: QuestionListScreen(assessmentId: widget.assessment.assessmentId),
    );
  }

  Widget _updateButton() {
    return Padding(
      padding: ResponsiveBreakpoints.of(context).isMobile
          ? const EdgeInsets.all(10)
          : const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key("assessmentDetailDelete"),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
              ),
              child: const Text('Delete'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Assessment'),
                      content: const Text(
                        'Are you sure you want to delete this assessment?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true && mounted) {
                  _assessmentBloc.add(
                    AssessmentDelete(widget.assessment),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              key: const Key("assessmentDetailSave"),
              child: const Text('Save'),
              onPressed: () async {
                updatedAssessment = widget.assessment.copyWith(
                  pseudoId: _pseudoIdController.text,
                  assessmentName: _nameController.text,
                  description: _descriptionController.text,
                  status: _selectedStatus,
                );
                _assessmentBloc.add(AssessmentUpdate(updatedAssessment));
              },
            ),
          ),
        ],
      ),
    );
  }
}
