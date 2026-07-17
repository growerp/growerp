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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/page_section_bloc.dart';
import '../bloc/page_section_event.dart';
import '../bloc/page_section_state.dart';

const List<String> pageSectionTypes = [
  'text',
  'stats',
  'cards',
  'timeline',
  'benefits',
];

/// One structured content row for a non-text section. Holds a controller for
/// every field used by any sectionType; toJson()/fromJson() pick the subset
/// that applies to the given type. See PageSection.contentJson row shapes in
/// backend/entity/LandingPageEntities.xml.
class _ContentRow {
  final TextEditingController value = TextEditingController(); // stats
  final TextEditingController label = TextEditingController(); // stats
  final TextEditingController tag = TextEditingController(); // cards
  final TextEditingController title = TextEditingController(); // cards, timeline
  final TextEditingController description =
      TextEditingController(); // cards, timeline
  final TextEditingController points =
      TextEditingController(); // cards, one bullet per line
  final TextEditingController footer = TextEditingController(); // cards
  final TextEditingController icon = TextEditingController(); // benefits
  final TextEditingController text = TextEditingController(); // benefits

  void dispose() {
    for (final c in [
      value,
      label,
      tag,
      title,
      description,
      points,
      footer,
      icon,
      text,
    ]) {
      c.dispose();
    }
  }

  Map<String, dynamic> toJson(String sectionType) {
    switch (sectionType) {
      case 'stats':
        return {'value': value.text, 'label': label.text};
      case 'cards':
        return {
          'tag': tag.text,
          'title': title.text,
          'description': description.text,
          'points': points.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          'footer': footer.text,
        };
      case 'timeline':
        return {'title': title.text, 'description': description.text};
      case 'benefits':
        return {'icon': icon.text, 'text': text.text};
      default:
        return {};
    }
  }

  static _ContentRow fromJson(String sectionType, Map<String, dynamic> json) {
    final row = _ContentRow();
    switch (sectionType) {
      case 'stats':
        row.value.text = json['value']?.toString() ?? '';
        row.label.text = json['label']?.toString() ?? '';
        break;
      case 'cards':
        row.tag.text = json['tag']?.toString() ?? '';
        row.title.text = json['title']?.toString() ?? '';
        row.description.text = json['description']?.toString() ?? '';
        final points = json['points'];
        row.points.text = points is List ? points.join('\n') : '';
        row.footer.text = json['footer']?.toString() ?? '';
        break;
      case 'timeline':
        row.title.text = json['title']?.toString() ?? '';
        row.description.text = json['description']?.toString() ?? '';
        break;
      case 'benefits':
        row.icon.text = json['icon']?.toString() ?? '';
        row.text.text = json['text']?.toString() ?? '';
        break;
    }
    return row;
  }
}

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
  late String _selectedSectionType;
  final List<_ContentRow> _rows = [];
  late PageSectionBloc _sectionBloc;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.section.sectionTitle ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.section.sectionDescription ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.section.sectionImageUrl ?? '',
    );
    _sequenceController = TextEditingController(
      text: widget.section.sectionSequence?.toString() ?? '',
    );
    _selectedSectionType =
        (widget.section.sectionType?.isNotEmpty ?? false)
        ? widget.section.sectionType!
        : 'text';

    final contentJson = widget.section.contentJson;
    if (_selectedSectionType != 'text' &&
        contentJson != null &&
        contentJson.isNotEmpty) {
      try {
        final parsed = jsonDecode(contentJson);
        if (parsed is List) {
          for (final row in parsed) {
            if (row is Map<String, dynamic>) {
              _rows.add(_ContentRow.fromJson(_selectedSectionType, row));
            }
          }
        }
      } catch (_) {
        // invalid JSON: start with an empty row list rather than fail to open
      }
    }

    _sectionBloc = context.read<PageSectionBloc>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _sequenceController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
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
        height: 600,
        child: BlocConsumer<PageSectionBloc, PageSectionState>(
          listenWhen: (previous, current) =>
              previous.status == PageSectionStatus.loading &&
              (current.status == PageSectionStatus.success ||
                  current.status == PageSectionStatus.failure),
          listener: (context, state) {
            if (state.status == PageSectionStatus.failure) {
              HelperFunctions.showMessage(
                context,
                state.message ?? 'Error',
                Colors.red,
              );
            }
            // Only pop after a save (create/update), not after a section load.
            // Create/update success always includes a non-null message.
            if (state.status == PageSectionStatus.success &&
                state.message != null) {
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: const Key('sectionType'),
                        decoration: const InputDecoration(
                          labelText: 'Section Type',
                        ),
                        initialValue: _selectedSectionType,
                        items: pageSectionTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            for (final row in _rows) {
                              row.dispose();
                            }
                            _rows.clear();
                            _selectedSectionType = value ?? 'text';
                          });
                        },
                      ),
                      if (_selectedSectionType != 'text') ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Content Rows',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        ..._rows.asMap().entries.map(
                          (entry) => _buildRow(entry.key, entry.value),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('addContentRow'),
                            onPressed: () =>
                                setState(() => _rows.add(_ContentRow())),
                            icon: const Icon(Icons.add),
                            label: const Text('Add row'),
                          ),
                        ),
                      ],
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
                              onPressed: () => _save(isNew),
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

  Widget _buildRow(int index, _ContentRow row) {
    List<Widget> fields;
    switch (_selectedSectionType) {
      case 'stats':
        fields = [
          Expanded(
            child: TextFormField(
              key: Key('rowValue$index'),
              controller: row.value,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: Key('rowLabel$index'),
              controller: row.label,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
          ),
        ];
        break;
      case 'timeline':
        fields = [
          Expanded(
            child: TextFormField(
              key: Key('rowTitle$index'),
              controller: row.title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: Key('rowDescription$index'),
              controller: row.description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ),
        ];
        break;
      case 'benefits':
        fields = [
          Expanded(
            child: TextFormField(
              key: Key('rowIcon$index'),
              controller: row.icon,
              decoration: const InputDecoration(labelText: 'Icon'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: Key('rowText$index'),
              controller: row.text,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
          ),
        ];
        break;
      case 'cards':
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: Key('rowTag$index'),
                          controller: row.tag,
                          decoration: const InputDecoration(labelText: 'Tag'),
                        ),
                      ),
                      IconButton(
                        key: Key('rowDelete$index'),
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            setState(() => _rows.removeAt(index).dispose()),
                      ),
                    ],
                  ),
                  TextFormField(
                    key: Key('rowTitle$index'),
                    controller: row.title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextFormField(
                    key: Key('rowDescription$index'),
                    controller: row.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    maxLines: 2,
                  ),
                  TextFormField(
                    key: Key('rowPoints$index'),
                    controller: row.points,
                    decoration: const InputDecoration(
                      labelText: 'Points (one per line)',
                    ),
                    maxLines: 3,
                  ),
                  TextFormField(
                    key: Key('rowFooter$index'),
                    controller: row.footer,
                    decoration: const InputDecoration(labelText: 'Footer tag'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ...fields,
          IconButton(
            key: Key('rowDelete$index'),
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => _rows.removeAt(index).dispose()),
          ),
        ],
      ),
    );
  }

  void _save(bool isNew) {
    if (_formKey.currentState?.validate() != true) return;

    final contentJson = _selectedSectionType == 'text'
        ? null
        : jsonEncode(_rows.map((r) => r.toJson(_selectedSectionType)).toList());

    if (isNew) {
      _sectionBloc.add(
        PageSectionCreate(
          landingPageId: widget.landingPageId,
          sectionTitle: _titleController.text,
          sectionDescription: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          sectionImageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
          sectionType: _selectedSectionType,
          contentJson: contentJson,
          sectionSequence: _sequenceController.text.isEmpty
              ? null
              : int.tryParse(_sequenceController.text),
        ),
      );
    } else {
      _sectionBloc.add(
        PageSectionUpdate(
          pageSectionId: widget.section.landingPageSectionId!,
          sectionTitle: _titleController.text,
          sectionDescription: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          sectionImageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
          sectionType: _selectedSectionType,
          contentJson: contentJson,
          sectionSequence: _sequenceController.text.isEmpty
              ? null
              : int.tryParse(_sequenceController.text),
        ),
      );
    }
  }
}
