/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_courses/growerp_courses.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

/// Dialog for enrolling a participant in a course.
///
/// Two modes:
/// - [participant] == null: new enrollment — search or create participant,
///   then select a course.
/// - [participant] != null: add course — participant is pre-selected (read-only),
///   only course selection is shown.
class ElearnerParticipantDialog extends StatefulWidget {
  final CourseParticipant? participant;
  const ElearnerParticipantDialog({super.key, this.participant});

  @override
  State<ElearnerParticipantDialog> createState() =>
      _ElearnerParticipantDialogState();
}

class _ElearnerParticipantDialogState
    extends State<ElearnerParticipantDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  // Participant state (only used when participant == null)
  CompanyUser? _selectedSubscriber;
  bool _showCreateForm = true;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Course
  Course? _selectedCourse;

  late SubscriptionBloc _subscriptionBloc;
  late DataFetchBloc<CompaniesUsers> _companyUserBloc;
  late CourseBloc _courseBloc;

  bool _isSaving = false;

  bool get _isAddingCourse => widget.participant != null;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = context.read<SubscriptionBloc>();
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getCompanyUser(
                limit: 5,
                role: Role.customer,
              ),
        ),
      );
    _courseBloc = context.read<CourseBloc>()
      ..add(const CourseFetch(refresh: true));

    // Pre-fill course from the participant's current enrollment
    final p = widget.participant;
    if (p != null && p.courseId != null) {
      _selectedCourse = Course(
        courseId: p.courseId,
        title: p.courseTitle ?? '',
      );
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listenWhen: (_, current) =>
          current.status == SubscriptionStatus.failure ||
          current.status == SubscriptionStatus.success,
      listener: (context, state) {
        if (state.status == SubscriptionStatus.success) {
          Navigator.of(context).pop();
        } else if (state.status == SubscriptionStatus.failure) {
          setState(() => _isSaving = false);
          HelperFunctions.showMessage(
            context,
            state.message ?? 'Error saving enrollment',
            Colors.red,
          );
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: _isAddingCourse ? 'Add/Create Participant' : 'New Enrollment',
          width: 440,
          height: _isAddingCourse ? 560 : (_showCreateForm ? 700 : 560),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'fromDate': DateTime.now().toLocal(),
        'thruDate': DateTime.now().toLocal().add(const Duration(days: 90)),
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Participant section ──────────────────────────────────────
            _buildParticipantSection(),

            const SizedBox(height: 16),

            // ── Course selection ─────────────────────────────────────────
            AutocompleteLabel<Course>(
              key: const Key('course'),
              label: 'Course',
              initialValue: _selectedCourse,
              validator: (v) => v == null ? 'Required' : null,
              optionsBuilder: (textValue) {
                _courseBloc.add(
                  CourseFetch(searchString: textValue.text, refresh: true),
                );
                return Future.delayed(
                  const Duration(milliseconds: 150),
                  () => _courseBloc.state.courses,
                );
              },
              displayStringForOption: (c) => c.title,
              onSelected: (c) => setState(() => _selectedCourse = c),
            ),

            const SizedBox(height: 16),

            // ── Date pickers ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'fromDate',
                    key: const Key('fromDate'),
                    inputType: InputType.date,
                    format: DateFormat('yyyy-MM-dd'),
                    decoration: const InputDecoration(
                      labelText: 'From date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'thruDate',
                    key: const Key('thruDate'),
                    inputType: InputType.date,
                    format: DateFormat('yyyy-MM-dd'),
                    decoration: const InputDecoration(
                      labelText: 'Thru date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Save ─────────────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _onSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enroll'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSection() {
    // When adding a course to an existing participant, show details read-only
    if (_isAddingCourse) {
      final p = widget.participant!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadOnlyField(label: 'First name', value: p.firstName ?? ''),
          const SizedBox(height: 8),
          _ReadOnlyField(label: 'Last name', value: p.lastName ?? ''),
          const SizedBox(height: 8),
          _ReadOnlyField(label: 'Email', value: p.username ?? ''),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search existing participants
        AutocompleteLabel<CompanyUser>(
          key: const Key('subscriber'),
          label: 'Participant',
          initialValue: _selectedSubscriber,
          validator: (v) {
            if (_showCreateForm) return null;
            return v == null ? 'Select or create a participant' : null;
          },
          optionsBuilder: (textValue) {
            _companyUserBloc.add(
              GetDataEvent(
                () => context.read<RestClient>().getCompanyUser(
                      searchString: textValue.text,
                      limit: 5,
                      role: Role.customer,
                    ),
              ),
            );
            return Future.delayed(
              const Duration(milliseconds: 150),
              () => (_companyUserBloc.state.data as CompaniesUsers)
                  .companiesUsers,
            );
          },
          displayStringForOption: (u) =>
              '${u.name ?? ''} ${u.company?.name ?? ''}'.trim(),
          onSelected: (u) => setState(() {
            _selectedSubscriber = u;
            if (_showCreateForm) {
              _showCreateForm = false;
              _firstNameCtrl.clear();
              _lastNameCtrl.clear();
              _emailCtrl.clear();
            }
          }),
        ),

        const SizedBox(height: 6),

        // Toggle: "Create new participant" / "Cancel — use existing"
        InkWell(
          onTap: () => setState(() {
            _showCreateForm = !_showCreateForm;
            if (_showCreateForm) {
              _selectedSubscriber = null;
            } else {
              _firstNameCtrl.clear();
              _lastNameCtrl.clear();
              _emailCtrl.clear();
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _showCreateForm ? Icons.cancel_outlined : Icons.person_add,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _showCreateForm
                      ? 'Cancel — use existing participant'
                      : 'Create new participant',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Inline create-new form
        if (_showCreateForm) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New participant details',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (login)',
                    hintText: 'participant@example.com',
                  ),
                  validator: (v) {
                    if (!_showCreateForm) return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'A welcome email with login details will be sent.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onSave() async {
    final isValid = _formKey.currentState!.saveAndValidate();

    bool participantValid;
    if (_isAddingCourse) {
      participantValid = widget.participant!.partyId != null;
    } else if (_showCreateForm) {
      participantValid = _firstNameCtrl.text.trim().isNotEmpty &&
          _emailCtrl.text.trim().isNotEmpty &&
          _emailCtrl.text.contains('@');
    } else {
      participantValid = _selectedSubscriber != null;
    }

    if (!isValid || _selectedCourse == null || !participantValid) return;

    setState(() => _isSaving = true);

    final formData = _formKey.currentState!.value;
    final fromDate = formData['fromDate'] as DateTime?;
    final thruDate = formData['thruDate'] as DateTime?;
    final restClient = context.read<RestClient>();

    CompanyUser? subscriber;

    if (_isAddingCourse) {
      subscriber = CompanyUser(partyId: widget.participant!.partyId);
    } else {
      subscriber = _selectedSubscriber;
    }

    try {
      if (!_isAddingCourse && _showCreateForm) {
        final email = _emailCtrl.text.trim();
        final created = await restClient.createUser(
          user: User(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim().isEmpty
                ? null
                : _lastNameCtrl.text.trim(),
            email: email,
            loginName: email,
            userGroup: UserGroup.other,
            role: Role.customer,
          ),
        );
        subscriber = CompanyUser(
          partyId: created.partyId,
          name:
              '${created.firstName ?? ''} ${created.lastName ?? ''}'.trim(),
        );
      }

      // If the pre-filled stub course lacks a productId, look it up from the
      // bloc's loaded courses list (which has full data including productId).
      Course resolvedCourse = _selectedCourse!;
      if (resolvedCourse.productId == null && resolvedCourse.courseId != null) {
        final match = _courseBloc.state.courses.firstWhere(
          (c) => c.courseId == resolvedCourse.courseId,
          orElse: () => resolvedCourse,
        );
        resolvedCourse = match;
      }
      final courseProductId = resolvedCourse.productId;
      if (courseProductId == null) {
        if (mounted) {
          HelperFunctions.showMessage(
            context,
            'Selected course has no product ID. Cannot create enrollment.',
            Colors.red,
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      _subscriptionBloc.add(
        SubscriptionUpdate(
          Subscription(
            fromDate: fromDate?.noon().toServerTime(),
            thruDate: thruDate?.noon().toServerTime(),
            subscriber: subscriber,
            product: Product(
              productId: courseProductId,
              productName: resolvedCourse.title,
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Failed to create participant: $e',
          Colors.red,
        );
      }
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(labelText: label),
    );
  }
}
