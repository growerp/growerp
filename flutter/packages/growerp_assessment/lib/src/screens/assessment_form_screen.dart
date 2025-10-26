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
import '../bloc/assessment_bloc.dart';

/// Dialog for creating a new assessment
class CreateAssessmentDialog extends StatefulWidget {
  const CreateAssessmentDialog({super.key});

  @override
  State<CreateAssessmentDialog> createState() => _CreateAssessmentDialogState();
}

class _CreateAssessmentDialogState extends State<CreateAssessmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'DRAFT';
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'DRAFT',
    'ACTIVE',
    'INACTIVE',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_add, color: Colors.green[700]),
          const SizedBox(width: 8),
          const Text('Create Assessment'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const Key('name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Assessment Name *',
                  hintText: 'Enter a descriptive name',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Assessment name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Name must be less than 100 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('description'),
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this assessment measures',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
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
                        'After creating the assessment, you can add questions and configure scoring.',
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
          key: const Key('createAssessment'),
          onPressed: _isLoading ? null : _createAssessment,
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
              : const Text('Create Assessment'),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'INACTIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _createAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assessment = Assessment(
        assessmentId: '', // Will be generated by backend
        pseudoId: '', // Will be generated by backend
        assessmentName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: _selectedStatus,
        createdDate: DateTime.now(),
      );

      if (mounted) {
        context.read<AssessmentBloc>().add(AssessmentCreate(assessment));
        Navigator.of(context).pop();

        // Show success message
        HelperFunctions.showMessage(
          context,
          'Assessment "${assessment.assessmentName}" created successfully',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to create assessment: $e',
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

/// Screen for creating/editing assessments with a full form
class AssessmentFormScreen extends StatefulWidget {
  final Assessment? assessment; // null for create, non-null for edit

  const AssessmentFormScreen({
    super.key,
    this.assessment,
  });

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'DRAFT';
  bool _isLoading = false;
  bool get _isEditing => widget.assessment != null;

  final List<String> _statusOptions = [
    'DRAFT',
    'ACTIVE',
    'INACTIVE',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.assessment!.assessmentName;
      _descriptionController.text = widget.assessment!.description ?? '';
      _selectedStatus = widget.assessment!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Assessment' : 'Create Assessment'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAssessment,
              tooltip: 'Delete Assessment',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('ID', widget.assessment!.assessmentId),
                      _buildInfoRow('Pseudo ID', widget.assessment!.pseudoId),
                      _buildInfoRow('Created',
                          _formatDate(widget.assessment!.createdDate)),
                      if (widget.assessment!.createdByUserLogin != null)
                        _buildInfoRow('Created By',
                            widget.assessment!.createdByUserLogin!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Assessment Name *',
                        hintText: 'Enter a descriptive name',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Assessment name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        if (value.trim().length > 100) {
                          return 'Name must be less than 100 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe what this assessment measures',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      maxLength: 500,
                      validator: (value) {
                        if (value != null && value.trim().length > 500) {
                          return 'Description must be less than 500 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Creating Effective Assessments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Use clear, specific names that describe the assessment purpose\n'
                    '• Write detailed descriptions to help users understand what they\'re taking\n'
                    '• Start with DRAFT status to test before making it ACTIVE\n'
                    '• Add questions after creating the assessment',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAssessment,
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Assessment'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'INACTIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final assessment = _isEditing
          ? widget.assessment!.copyWith(
              assessmentName: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              status: _selectedStatus,
            )
          : Assessment(
              assessmentId: '', // Will be generated by backend
              pseudoId: '', // Will be generated by backend
              assessmentName: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              status: _selectedStatus,
              createdDate: DateTime.now(),
            );

      if (mounted) {
        if (_isEditing) {
          context.read<AssessmentBloc>().add(AssessmentUpdate(assessment));
        } else {
          context.read<AssessmentBloc>().add(AssessmentCreate(assessment));
        }

        Navigator.of(context).pop();

        // Show success message
        HelperFunctions.showMessage(
          context,
          _isEditing
              ? 'Assessment updated successfully'
              : 'Assessment "${assessment.assessmentName}" created successfully',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          _isEditing
              ? 'Failed to update assessment: $e'
              : 'Failed to create assessment: $e',
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

  void _deleteAssessment() {
    if (widget.assessment == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Assessment'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.assessment!.assessmentName}"?\n\n'
          'This will also delete all associated questions and results. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close form screen
              context
                  .read<AssessmentBloc>()
                  .add(AssessmentDelete(widget.assessment!));
              HelperFunctions.showMessage(
                context,
                'Assessment deleted successfully',
                Colors.green,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
