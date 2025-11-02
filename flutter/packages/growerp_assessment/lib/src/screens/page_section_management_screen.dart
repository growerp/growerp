import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/page_section_bloc.dart';
import '../bloc/page_section_event.dart';
import '../bloc/page_section_state.dart';
import 'page_section_dialog.dart';

class PageSectionManagementScreen extends StatefulWidget {
  final String pageId;
  final String pageTitle;

  const PageSectionManagementScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
  });

  @override
  State<PageSectionManagementScreen> createState() =>
      _PageSectionManagementScreenState();
}

class _PageSectionManagementScreenState
    extends State<PageSectionManagementScreen> {
  late PageSectionBloc _pageSectionBloc;

  @override
  void initState() {
    super.initState();
    _pageSectionBloc = context.read<PageSectionBloc>();
    _pageSectionBloc.add(PageSectionLoad(widget.pageId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sections - ${widget.pageTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSectionDialog(),
          ),
        ],
      ),
      body: BlocConsumer<PageSectionBloc, PageSectionState>(
        listener: (context, state) {
          if (state.status == PageSectionStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'An error occurred',
              Colors.red,
            );
          } else if (state.message != null &&
              state.status == PageSectionStatus.success) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        },
        builder: (context, state) {
          return _buildSectionsList(state);
        },
      ),
    );
  }

  Widget _buildSectionsList(PageSectionState state) {
    if (state.status == PageSectionStatus.loading && state.sections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.view_agenda_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No sections found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add sections to organize your landing page content',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showSectionDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Section'),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: state.sections.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        _reorderSections(oldIndex, newIndex, state.sections);
      },
      itemBuilder: (context, index) {
        final section = state.sections[index];
        return _buildSectionCard(section, index);
      },
    );
  }

  Widget _buildSectionCard(LandingPageSection section, int index) {
    return Card(
      key: ValueKey(section.sectionId),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          section.sectionTitle ?? 'Section',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.sectionDescription != null) ...[
              Text(
                section.sectionDescription!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'ID: ${section.pseudoId} • Order: ${section.sectionSequence ?? 0}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, section),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Duplicate'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () => _showSectionDialog(section: section),
      ),
    );
  }

  void _handleMenuAction(String action, LandingPageSection section) {
    switch (action) {
      case 'edit':
        _showSectionDialog(section: section);
        break;
      case 'duplicate':
        _duplicateSection(section);
        break;
      case 'delete':
        _confirmDelete(section);
        break;
    }
  }

  void _showSectionDialog({LandingPageSection? section}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider.value(
        value: _pageSectionBloc,
        child: PageSectionDialog(
          pageId: widget.pageId,
          section: section,
        ),
      ),
    );
  }

  void _duplicateSection(LandingPageSection section) {
    _pageSectionBloc.add(PageSectionCreate(
      pageId: widget.pageId,
      sectionTitle: '${section.sectionTitle ?? 'Section'} (Copy)',
      sectionDescription: section.sectionDescription,
      sectionImageUrl: section.sectionImageUrl,
      sectionSequence: (section.sectionSequence ?? 0) + 1,
    ));
  }

  void _confirmDelete(LandingPageSection section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
          'Are you sure you want to delete "${section.sectionTitle ?? 'Section'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pageSectionBloc.add(PageSectionDelete(section.sectionId ?? ''));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reorderSections(
      int oldIndex, int newIndex, List<LandingPageSection> sections) {
    final section = sections[oldIndex];
    final newSequenceNum = newIndex + 1;

    if ((section.sectionSequence ?? 0) != newSequenceNum) {
      _pageSectionBloc.add(PageSectionUpdate(
        sectionId: section.sectionId ?? '',
        sectionSequence: newSequenceNum,
      ));
    }
  }
}
