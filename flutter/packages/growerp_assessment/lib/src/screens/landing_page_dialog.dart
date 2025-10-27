import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import '../bloc/assessment_bloc.dart';
import 'page_section_management_screen.dart';
import 'credibility_management_screen.dart';
import 'cta_management_screen.dart';

class LandingPageDialog extends StatefulWidget {
  final LandingPage? landingPage;

  const LandingPageDialog({
    super.key,
    this.landingPage,
  });

  @override
  State<LandingPageDialog> createState() => _LandingPageDialogState();
}

class _LandingPageDialogState extends State<LandingPageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _pseudoIdController = TextEditingController();
  final _headlineController = TextEditingController();
  final _subheadingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _heroImageUrlController = TextEditingController();

  String _selectedStatus = 'DRAFT';
  String? _selectedHookType;
  String? _selectedAssessmentId;

  final List<String> _statusOptions = ['DRAFT', 'ACTIVE', 'INACTIVE'];
  final List<String> _hookTypeOptions = [
    'problem',
    'opportunity',
    'results',
    'frustration',
    'aspiration',
    'curiosity'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.landingPage != null) {
      _populateFields(widget.landingPage!);
    }
  }

  void _populateFields(LandingPage landingPage) {
    _titleController.text = landingPage.title;
    _pseudoIdController.text = landingPage.pseudoId;
    _headlineController.text = landingPage.headline;
    _subheadingController.text = landingPage.subheading ?? '';
    _descriptionController.text = landingPage.description ?? '';
    _heroImageUrlController.text = landingPage.heroImageUrl ?? '';
    _selectedStatus = landingPage.status;
    _selectedHookType = landingPage.hookType;
    _selectedAssessmentId = landingPage.assessmentId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pseudoIdController.dispose();
    _headlineController.dispose();
    _subheadingController.dispose();
    _descriptionController.dispose();
    _heroImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.landingPage != null && widget.landingPage!.pageId.isNotEmpty;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Landing Page' : 'Create Landing Page',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Page Title *',
                          hintText: 'Enter the page title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a page title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pseudoIdController,
                        decoration: const InputDecoration(
                          labelText: 'Page ID *',
                          hintText:
                              'URL-friendly identifier (e.g., business-assessment)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a page ID';
                          }
                          if (!RegExp(r'^[a-z0-9-_]+$').hasMatch(value)) {
                            return 'Page ID can only contain lowercase letters, numbers, hyphens, and underscores';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Content Section
                      Text(
                        'Content',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _headlineController,
                        decoration: const InputDecoration(
                          labelText: 'Headline *',
                          hintText: 'Main attention-grabbing headline',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a headline';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subheadingController,
                        decoration: const InputDecoration(
                          labelText: 'Subheading',
                          hintText: 'Supporting text under the headline',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedHookType,
                        decoration: const InputDecoration(
                          labelText: 'Hook Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select hook type'),
                          ),
                          ..._hookTypeOptions.map((hookType) {
                            return DropdownMenuItem(
                              value: hookType,
                              child: Text(hookType.toUpperCase()),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedHookType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AssessmentBloc, AssessmentState>(
                        builder: (context, state) {
                          // Ensure the selected assessment ID is valid or null
                          final validAssessmentIds = state.assessments
                              .map((a) => a.assessmentId)
                              .toSet();
                          final selectedValue = _selectedAssessmentId != null &&
                                  validAssessmentIds
                                      .contains(_selectedAssessmentId)
                              ? _selectedAssessmentId
                              : null;

                          return DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: selectedValue,
                            decoration: const InputDecoration(
                              labelText: 'Associated Assessment',
                              hintText:
                                  'Select an assessment to link to this page',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None'),
                              ),
                              ...state.assessments.map((assessment) {
                                return DropdownMenuItem<String?>(
                                  value: assessment.assessmentId,
                                  child: Text(assessment.assessmentName),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedAssessmentId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'SEO meta description and page summary',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _heroImageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Hero Image URL',
                          hintText: 'URL of the main hero image',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Component Management Section (only for existing pages)
                      if (isEditing && widget.landingPage != null) ...[
                        Text(
                          'Page Components',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _navigateToSectionManagement(),
                                icon: const Icon(Icons.view_module),
                                label: const Text('Manage Sections'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _navigateToCredibilityManagement(),
                                icon: const Icon(Icons.verified_user),
                                label: const Text('Credibility'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _navigateToCTAManagement(),
                                icon: const Icon(Icons.touch_app),
                                label: const Text('Call-to-Action'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                BlocConsumer<LandingPageBloc, LandingPageState>(
                  listener: (context, state) {
                    if (state.status == LandingPageStatus.success &&
                        state.message != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == LandingPageStatus.loading
                          ? null
                          : _saveLandingPage,
                      child: state.status == LandingPageStatus.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Update' : 'Create'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveLandingPage() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final landingPage = LandingPage(
      pageId: widget.landingPage?.pageId ?? '',
      pseudoId: _pseudoIdController.text.trim(),
      title: _titleController.text.trim(),
      headline: _headlineController.text.trim(),
      hookType: _selectedHookType,
      subheading: _subheadingController.text.trim().isEmpty
          ? null
          : _subheadingController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      heroImageUrl: _heroImageUrlController.text.trim().isEmpty
          ? null
          : _heroImageUrlController.text.trim(),
      status: _selectedStatus,
      assessmentId: _selectedAssessmentId,
    );

    final landingPageBloc = context.read<LandingPageBloc>();

    if (widget.landingPage != null && widget.landingPage!.pageId.isNotEmpty) {
      landingPageBloc.add(LandingPageUpdate(landingPage));
    } else {
      landingPageBloc.add(LandingPageCreate(landingPage));
    }
  }

  void _navigateToSectionManagement() {
    if (widget.landingPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PageSectionManagementScreen(
            pageId: widget.landingPage!.pageId,
            pageTitle: widget.landingPage!.title,
          ),
        ),
      );
    }
  }

  void _navigateToCredibilityManagement() {
    if (widget.landingPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CredibilityManagementScreen(
            pageId: widget.landingPage!.pageId,
            pageTitle: widget.landingPage!.title,
          ),
        ),
      );
    }
  }

  void _navigateToCTAManagement() {
    if (widget.landingPage != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CTAManagementScreen(
            pageId: widget.landingPage!.pageId,
            pageTitle: widget.landingPage!.title,
          ),
        ),
      );
    }
  }
}
