import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/page_section_bloc.dart';
import '../bloc/page_section_event.dart';
import '../bloc/page_section_state.dart';

class PageSectionDialog extends StatefulWidget {
  final String pageId;
  final LandingPageSection? section;

  const PageSectionDialog({
    super.key,
    required this.pageId,
    this.section,
  });

  @override
  State<PageSectionDialog> createState() => _PageSectionDialogState();
}

class _PageSectionDialogState extends State<PageSectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sequenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      _populateFields(widget.section!);
    }
  }

  void _populateFields(LandingPageSection section) {
    _titleController.text = section.sectionTitle ?? '';
    _descriptionController.text = section.sectionDescription ?? '';
    _imageUrlController.text = section.sectionImageUrl ?? '';
    _sequenceController.text = (section.sectionSequence ?? 0).toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.section != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Section' : 'Create Section',
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
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Section Title *',
                          hintText: 'Enter the section title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a section title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter the section description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/image.jpg',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final uri = Uri.tryParse(value);
                            if (uri == null || !uri.hasScheme) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sequenceController,
                        decoration: const InputDecoration(
                          labelText: 'Display Order',
                          hintText: 'Enter display order (1, 2, 3...)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final number = int.tryParse(value);
                            if (number == null || number < 1) {
                              return 'Please enter a valid number (1 or greater)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Preview section
                      if (_titleController.text.isNotEmpty) ...[
                        Text(
                          'Preview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleController.text,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (_descriptionController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(_descriptionController.text),
                                ],
                                if (_imageUrlController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text('Image Preview'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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
                BlocConsumer<PageSectionBloc, PageSectionState>(
                  listener: (context, state) {
                    if (state.status == PageSectionStatus.success &&
                        state.message != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == PageSectionStatus.loading
                          ? null
                          : _saveSection,
                      child: state.status == PageSectionStatus.loading
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

  void _saveSection() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sectionBloc = context.read<PageSectionBloc>();

    if (widget.section != null) {
      // Update existing section
      sectionBloc.add(PageSectionUpdate(
        sectionId: widget.section!.sectionId ?? '',
        sectionTitle: _titleController.text.trim(),
        sectionDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sectionImageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        sectionSequence: _sequenceController.text.trim().isEmpty
            ? null
            : int.tryParse(_sequenceController.text.trim()),
      ));
    } else {
      // Create new section
      sectionBloc.add(PageSectionCreate(
        pageId: widget.pageId,
        sectionTitle: _titleController.text.trim(),
        sectionDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sectionImageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        sectionSequence: _sequenceController.text.trim().isEmpty
            ? null
            : int.tryParse(_sequenceController.text.trim()),
      ));
    }
  }
}
