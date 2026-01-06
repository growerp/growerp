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

import '../bloc/page_section_bloc.dart';
import '../bloc/page_section_event.dart';
import '../bloc/page_section_state.dart';

class PageSectionDetailScreen extends StatefulWidget {
  final String landingPageId;
  final LandingPageSection section;

  const PageSectionDetailScreen({
    super.key,
    required this.landingPageId,
    required this.section,
  });

  @override
  PageSectionDetailScreenState createState() => PageSectionDetailScreenState();
}

class PageSectionDetailScreenState extends State<PageSectionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _sequenceController;
  late PageSectionBloc _sectionBloc;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.section.sectionTitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.section.sectionDescription ?? '');
    _imageUrlController =
        TextEditingController(text: widget.section.sectionImageUrl ?? '');
    _sequenceController = TextEditingController(
      text: widget.section.sectionSequence?.toString() ?? '',
    );
    _sectionBloc = context.read<PageSectionBloc>();
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
    final isNew = widget.section.landingPageSectionId == null;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: popUp(
        context: context,
        title: isNew ? 'New Section' : 'Edit Section',
        width: 600,
        height: 500,
        child: BlocConsumer<PageSectionBloc, PageSectionState>(
          listener: (context, state) {
            if (state.status == PageSectionStatus.failure) {
              HelperFunctions.showMessage(
                context,
                state.message ?? 'Error',
                Colors.red,
              );
            }
            if (state.status == PageSectionStatus.success) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state.status == PageSectionStatus.loading) {
              return const LoadingIndicator();
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('sectionTitle'),
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Section Title *',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('sectionDescription'),
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('sectionImageUrl'),
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/image.jpg',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.startsWith('http://') &&
                                !value.startsWith('https://')) {
                              return 'Image URL must start with http:// or https://';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('sectionSequence'),
                        controller: _sequenceController,
                        decoration: const InputDecoration(
                          labelText: 'Display Order',
                          hintText: '1, 2, 3...',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              key: const Key('saveSection'),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (isNew) {
                                    _sectionBloc.add(
                                      PageSectionCreate(
                                        landingPageId: widget.landingPageId,
                                        sectionTitle: _titleController.text,
                                        sectionDescription:
                                            _descriptionController.text.isEmpty
                                                ? null
                                                : _descriptionController.text,
                                        sectionImageUrl:
                                            _imageUrlController.text.isEmpty
                                                ? null
                                                : _imageUrlController.text,
                                        sectionSequence:
                                            _sequenceController.text.isEmpty
                                                ? null
                                                : int.tryParse(
                                                    _sequenceController.text),
                                      ),
                                    );
                                  } else {
                                    _sectionBloc.add(
                                      PageSectionUpdate(
                                        pageSectionId: widget
                                            .section.landingPageSectionId!,
                                        sectionTitle: _titleController.text,
                                        sectionDescription:
                                            _descriptionController.text.isEmpty
                                                ? null
                                                : _descriptionController.text,
                                        sectionImageUrl:
                                            _imageUrlController.text.isEmpty
                                                ? null
                                                : _imageUrlController.text,
                                        sectionSequence:
                                            _sequenceController.text.isEmpty
                                                ? null
                                                : int.tryParse(
                                                    _sequenceController.text),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
