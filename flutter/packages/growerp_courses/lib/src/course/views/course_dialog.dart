/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/course_bloc.dart';

class CourseDialog extends StatefulWidget {
  final Course? course;

  const CourseDialog({super.key, this.course});

  @override
  State<CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<CourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _objectivesController;
  late TextEditingController _durationController;
  CourseDifficulty _selectedDifficulty = CourseDifficulty.beginner;

  bool get isEdit => widget.course?.courseId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.course?.description ?? '',
    );
    _objectivesController = TextEditingController(
      text: widget.course?.objectives ?? '',
    );
    _durationController = TextEditingController(
      text: widget.course?.estimatedDuration?.toString() ?? '',
    );
    _selectedDifficulty =
        widget.course?.difficulty ?? CourseDifficulty.beginner;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _objectivesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Course' : 'New Course'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildObjectivesField(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDifficultyDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDurationField()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isEdit) ...[
                    _buildModulesSection(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildActionButtons(),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      key: const Key('courseTitle'),
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Course Title *',
        hintText: 'e.g., GrowERP Field Service Masterclass',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a course title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      key: const Key('courseDescription'),
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Brief overview of what this course covers',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildObjectivesField() {
    return TextFormField(
      key: const Key('courseObjectives'),
      controller: _objectivesController,
      decoration: const InputDecoration(
        labelText: 'Learning Objectives',
        hintText: 'What will learners be able to do after this course?',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildDifficultyDropdown() {
    return DropdownButtonFormField<CourseDifficulty>(
      key: const Key('courseDifficulty'),
      initialValue: _selectedDifficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
      ),
      items: CourseDifficulty.values.map((difficulty) {
        return DropdownMenuItem(
          value: difficulty,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: _getDifficultyColor(difficulty),
              ),
              const SizedBox(width: 8),
              Text(_getDifficultyLabel(difficulty)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedDifficulty = value);
        }
      },
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      key: const Key('courseDuration'),
      controller: _durationController,
      decoration: const InputDecoration(
        labelText: 'Duration (minutes)',
        hintText: 'e.g., 60',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildModulesSection() {
    final modules = widget.course?.modules ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Modules (${modules.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Module'),
              onPressed: () => _showAddModuleDialog(),
            ),
          ],
        ),
        const Divider(),
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No modules yet. Add your first module.'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return ExpansionTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(module.title),
                subtitle: Text('${module.lessons?.length ?? 0} lessons'),
                children: [
                  if (module.lessons != null)
                    ...module.lessons!.map(
                      (lesson) => ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 72,
                          right: 16,
                        ),
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(lesson.title),
                        subtitle: lesson.estimatedDuration != null
                            ? Text('${lesson.estimatedDuration} min')
                            : null,
                      ),
                    ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: const Icon(Icons.add, color: Colors.blue),
                    title: const Text(
                      'Add Lesson',
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () => _showAddLessonDialog(module),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEdit)
            TextButton(
              key: const Key('deleteCourse'),
              onPressed: _deleteCourse,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('saveCourse'),
            onPressed: _saveCourse,
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return Colors.green;
      case CourseDifficulty.intermediate:
        return Colors.orange;
      case CourseDifficulty.advanced:
        return Colors.red;
    }
  }

  String _getDifficultyLabel(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return 'Beginner';
      case CourseDifficulty.intermediate:
        return 'Intermediate';
      case CourseDifficulty.advanced:
        return 'Advanced';
    }
  }

  void _saveCourse() {
    if (!_formKey.currentState!.validate()) return;

    final course = Course(
      courseId: widget.course?.courseId,
      pseudoId: widget.course?.pseudoId,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      objectives: _objectivesController.text.isNotEmpty
          ? _objectivesController.text
          : null,
      difficulty: _selectedDifficulty,
      estimatedDuration: _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null,
    );

    if (isEdit) {
      context.read<CourseBloc>().add(CourseUpdate(course));
    } else {
      context.read<CourseBloc>().add(CourseCreate(course));
    }

    Navigator.pop(context);
  }

  void _deleteCourse() {
    if (widget.course == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${widget.course!.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CourseBloc>().add(CourseDelete(widget.course!));
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddModuleDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Module Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;

              context.read<CourseBloc>().add(
                    CourseModuleCreate(
                      courseId: widget.course!.courseId!,
                      module: CourseModule(
                        title: titleController.text,
                        description: descController.text.isNotEmpty
                            ? descController.text
                            : null,
                      ),
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddLessonDialog(CourseModule module) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Lesson to ${module.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Lesson Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content (Markdown)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;

              context.read<CourseBloc>().add(
                    CourseLessonCreate(
                      moduleId: module.moduleId!,
                      lesson: CourseLesson(
                        title: titleController.text,
                        content: contentController.text.isNotEmpty
                            ? contentController.text
                            : null,
                      ),
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
