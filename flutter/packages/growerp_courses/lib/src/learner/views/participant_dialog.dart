/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_courses/l10n/generated/courses_localizations.dart';

import '../bloc/course_learner_bloc.dart';
import 'course_participant_list.dart';

/// Add or change a course participant and assign or remove their courses
class ParticipantDialog extends StatefulWidget {
  final CourseLearner? learner;

  const ParticipantDialog({super.key, this.learner});

  @override
  State<ParticipantDialog> createState() => _ParticipantDialogState();
}

class _ParticipantDialogState extends State<ParticipantDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  late CourseLearner _learner;

  @override
  void initState() {
    super.initState();
    _learner = widget.learner ?? CourseLearner();
  }

  bool get _isNew => _learner.partyId == null;

  void _save() {
    if (!_formKey.currentState!.saveAndValidate()) return;
    final values = _formKey.currentState!.value;
    context.read<CourseLearnerBloc>().add(
      CourseLearnerUpdate(
        CourseLearner(
          partyId: _learner.partyId,
          pseudoId: _learner.pseudoId,
          userId: _learner.userId,
          firstName: values['firstName'],
          lastName: values['lastName'],
          email: values['email'],
          courses: _learner.courses,
        ),
      ),
    );
  }

  Future<void> _remove(CourseLearnerCourse course) async {
    final l = CoursesLocalizations.of(context)!;
    final ok = await confirmDialog(
      context,
      l.courses_learnerRemoveTitle,
      course.paid == true
          ? l.courses_learnerRemovePaid
          : l.courses_learnerRemoveFree,
    );
    if (ok == true && mounted) {
      context.read<CourseLearnerBloc>().add(
        CourseLearnerUnassign(_learner, course.courseId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = CoursesLocalizations.of(context)!;
    return BlocConsumer<CourseLearnerBloc, CourseLearnerState>(
      listener: (context, state) {
        if (state.status == CourseLearnerStatus.failure) {
          HelperFunctions.showMessage(
            context,
            translateLearnerMessage(context, state.message ?? ''),
            Colors.red,
          );
        }
        if (state.status == CourseLearnerStatus.success &&
            state.message != null) {
          final selected = state.selected;
          // a new person: the one just created
          if (selected != null &&
              (selected.partyId == _learner.partyId ||
                  (_isNew && state.message == 'learnerAddSuccess'))) {
            setState(() => _learner = selected);
          }
          HelperFunctions.showMessage(
            context,
            translateLearnerMessage(context, state.message!),
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == CourseLearnerStatus.loading;
        return Dialog(
          key: const Key('ParticipantDialog'),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: popUp(
            context: context,
            title: _isNew ? l.courses_learnerNew : l.courses_learnerEdit,
            width: 500,
            height: MediaQuery.of(context).size.height * 0.8,
            child: ScaffoldMessenger(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: SingleChildScrollView(
                  key: const Key('listView'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _personForm(l, loading),
                      const SizedBox(height: 24),
                      Text(
                        l.courses_learnerCourses,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._courses(l, state, loading),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _personForm(CoursesLocalizations l, bool loading) {
    final required = FormBuilderValidators.required<String>(
      errorText: l.courses_fieldRequired,
    );
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'firstName': _learner.firstName ?? '',
        'lastName': _learner.lastName ?? '',
        'email': _learner.email ?? '',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBuilderTextField(
            name: 'firstName',
            key: const Key('firstName'),
            decoration: InputDecoration(labelText: l.courses_firstName),
            validator: required,
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'lastName',
            key: const Key('lastName'),
            decoration: InputDecoration(labelText: l.courses_lastName),
            validator: required,
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'email',
            key: const Key('email'),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.courses_email),
            validator: FormBuilderValidators.compose([
              required,
              FormBuilderValidators.email(errorText: l.courses_invalidEmail),
            ]),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const Key('update'),
            onPressed: loading ? null : _save,
            child: Text(_isNew ? l.courses_save : l.courses_update),
          ),
        ],
      ),
    );
  }

  List<Widget> _courses(
    CoursesLocalizations l,
    CourseLearnerState state,
    bool loading,
  ) {
    if (_isNew) return [Text(l.courses_learnerSaveFirst)];
    final assigned = _learner.courses.map((c) => c.courseId).toSet();
    final available = state.courses
        .where((c) => c.courseId != null && !assigned.contains(c.courseId))
        .toList();
    return [
      if (_learner.courses.isEmpty) Text(l.courses_learnerNoCourses),
      for (var i = 0; i < _learner.courses.length; i++)
        _courseTile(l, _learner.courses[i], i, loading),
      const SizedBox(height: 12),
      // a fresh field after every change: the assigned course leaves the items
      KeyedSubtree(
        key: ValueKey(assigned.join(',')),
        child: _assignField(l, available, loading),
      ),
    ];
  }

  Widget _assignField(
    CoursesLocalizations l,
    List<Course> available,
    bool loading,
  ) {
    return DropdownButtonFormField<String>(
        key: const Key('assignCourse'),
        isExpanded: true,
        decoration: InputDecoration(labelText: l.courses_learnerAssignCourse),
        items: [
          for (var i = 0; i < available.length; i++)
            DropdownMenuItem(
              key: Key('assignCourse$i'),
              value: available[i].courseId,
              child: Text(available[i].title, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: loading
            ? null
            : (courseId) {
                if (courseId == null) return;
                context.read<CourseLearnerBloc>().add(
                  CourseLearnerAssign(_learner, courseId),
                );
              },
      );
  }

  Widget _courseTile(
    CoursesLocalizations l,
    CourseLearnerCourse course,
    int index,
    bool loading,
  ) {
    final progress = course.progressPercent ?? 0;
    return ListTile(
      key: Key('learnerCourse$index'),
      contentPadding: EdgeInsets.zero,
      title: Text(course.title ?? ''),
      subtitle: Row(
        children: [
          Expanded(child: LinearProgressIndicator(value: progress / 100)),
          const SizedBox(width: 8),
          Text(l.courses_progress(progress.toString())),
          const SizedBox(width: 8),
          Text(course.paid == true ? l.courses_paid : l.courses_free),
        ],
      ),
      trailing: IconButton(
        key: Key('removeCourse$index'),
        tooltip: l.courses_remove,
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
        onPressed: loading ? null : () => _remove(course),
      ),
    );
  }
}
