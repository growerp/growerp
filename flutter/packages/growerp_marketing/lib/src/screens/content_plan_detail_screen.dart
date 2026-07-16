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
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/content_plan_bloc.dart';
import '../bloc/content_plan_event.dart';
import '../bloc/content_plan_state.dart';
import '../bloc/master_content_bloc.dart';
import '../bloc/master_content_event.dart';
import '../bloc/master_content_state.dart';
import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';
import 'master_content_detail_screen.dart';

class ContentPlanDetailScreen extends StatefulWidget {
  final ContentPlan? contentPlan;

  const ContentPlanDetailScreen({
    super.key,
    this.contentPlan,
  });

  @override
  ContentPlanDetailScreenState createState() => ContentPlanDetailScreenState();
}

class ContentPlanDetailScreenState extends State<ContentPlanDetailScreen> {
  late ScrollController _scrollController;
  late bool isPhone;
  late double top;
  double? right;
  late bool isVisible;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _pseudoIdController;
  late TextEditingController _themeController;
  DateTime? _weekStartDate;
  Persona? _selectedPersona;

  late ContentPlan updatedContentPlan;
  late ContentPlanBloc _contentPlanBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    top = 250; // Start lower on the screen
    isVisible = true;

    // Initialize form controllers
    _pseudoIdController =
        TextEditingController(text: widget.contentPlan?.pseudoId ?? '');
    _themeController =
        TextEditingController(text: widget.contentPlan?.theme ?? '');
    _weekStartDate = widget.contentPlan?.weekStartDate;

    updatedContentPlan = widget.contentPlan ?? const ContentPlan();
    _contentPlanBloc = context.read<ContentPlanBloc>();

    // Fetch personas for dropdown
    context
        .read<PersonaBloc>()
        .add(const PersonaFetch(refresh: true, limit: 100));

    // Fetch master content pieces for this plan
    if (widget.contentPlan?.planId != null) {
      context.read<MasterContentBloc>().add(
            MasterContentFetch(
              refresh: true,
              planId: widget.contentPlan!.planId,
            ),
          );
    }

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
    _pseudoIdController.dispose();
    _themeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 40);

    return Dialog(
      key: Key('ContentPlanDetail${widget.contentPlan?.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: "Content Plan #${widget.contentPlan?.pseudoId ?? 'New'}",
        width: isPhone ? 400 : 800,
        height: isPhone ? 600 : 500,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                BlocConsumer<ContentPlanBloc, ContentPlanState>(
                  listener: (context, state) {
                    if (state.status == ContentPlanStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Error',
                        Colors.red,
                      );
                    }
                    if (state.status == ContentPlanStatus.success &&
                        state.message != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    if (state.status == ContentPlanStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return _buildContent();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _weekStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _weekStartDate) {
      setState(() {
        _weekStartDate = picked;
      });
    }
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('contentPlanDetailListView'),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GroupingDecorator(
              labelText: 'Content Plan Information',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('pseudoId'),
                          decoration: const InputDecoration(
                            labelText: 'ID',
                            hintText: 'Leave empty to auto-generate',
                          ),
                          controller: _pseudoIdController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: BlocBuilder<PersonaBloc, PersonaState>(
                          builder: (context, personaState) {
                            // Set initial selected persona if we have a personaId
                            if (_selectedPersona == null &&
                                widget.contentPlan?.personaId != null &&
                                personaState.personas.isNotEmpty) {
                              _selectedPersona = personaState.personas
                                  .where((p) =>
                                      p.personaId ==
                                      widget.contentPlan?.personaId)
                                  .firstOrNull;
                            }
                            return DropdownButtonFormField<Persona>(
                              key: const Key('personaId'),
                              decoration: const InputDecoration(
                                labelText: 'Associated Persona',
                                hintText: 'Select a persona',
                              ),
                              initialValue: _selectedPersona,
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<Persona>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...personaState.personas.map((persona) {
                                  return DropdownMenuItem<Persona>(
                                    value: persona,
                                    child: Text(
                                      '${persona.name} (${persona.pseudoId ?? "N/A"})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (Persona? newValue) {
                                setState(() {
                                  _selectedPersona = newValue;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          key: const Key('weekStartDate'),
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Week Start Date',
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _weekStartDate != null
                                      ? DateFormat('MMM d, yyyy')
                                          .format(_weekStartDate!)
                                      : 'Select a date',
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText: 'Theme & Strategy',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('theme'),
                          decoration: const InputDecoration(
                            labelText: 'Theme',
                            hintText: 'Weekly content theme',
                          ),
                          controller: _themeController,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Content section — only show for existing plans
            if (widget.contentPlan?.planId != null) _buildContentSection(),
            const SizedBox(height: 20),
            _updateButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ADAPTED':
        return Colors.green;
      case 'APPROVED':
        return Colors.blue;
      case 'DRAFT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildContentSection() {
    return BlocBuilder<MasterContentBloc, MasterContentState>(
      builder: (context, contentState) {
        final contents = contentState.masterContents;
        return GroupingDecorator(
          labelText: 'Content',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (contentState.status == MasterContentStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (contents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No content yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...contents.asMap().entries.map((entry) {
                  final i = entry.key;
                  final content = entry.value;
                  return InkWell(
                    key: Key('contentRow$i'),
                    onTap: () async {
                      final masterContentBloc =
                          context.read<MasterContentBloc>();
                      await showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => BlocProvider.value(
                          value: masterContentBloc,
                          child: MasterContentDetailScreen(
                              masterContent: content),
                        ),
                      );
                      if (mounted && widget.contentPlan?.planId != null) {
                        masterContentBloc.add(MasterContentFetch(
                          refresh: true,
                          planId: widget.contentPlan!.planId,
                        ));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // PNP type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              content.pnpType,
                              key: Key('contentPnpType$i'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Title
                          Expanded(
                            child: Text(
                              content.title ?? 'No title',
                              key: Key('contentTitle$i'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(content.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              content.status,
                              key: Key('contentStatus$i'),
                              style: TextStyle(
                                fontSize: 10,
                                color: _statusColor(content.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Approve/revoke toggle — the auto-publish gate
                          IconButton(
                            key: Key('approveContent${content.pseudoId}'),
                            tooltip: content.approvedDate != null
                                ? 'Revoke approval'
                                : 'Approve — variants will auto-publish',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              content.approvedDate != null
                                  ? Icons.check_circle
                                  : Icons.hourglass_empty,
                              size: 18,
                              color: content.approvedDate != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: content.masterContentId == null
                                ? null
                                : () => context.read<MasterContentBloc>().add(
                                      MasterContentApprove(
                                        masterContentId:
                                            content.masterContentId!,
                                        approve: content.approvedDate == null,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              // Add content button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('addContent'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Content'),
                  onPressed: () async {
                    final masterContentBloc = context.read<MasterContentBloc>();
                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => BlocProvider.value(
                        value: masterContentBloc,
                        child: MasterContentDetailScreen(
                          masterContent: MasterContent(
                            planId: widget.contentPlan?.planId,
                            contentType: 'POSTING',
                            pnpType: 'PAIN',
                            status: 'DRAFT',
                          ),
                        ),
                      ),
                    );
                    if (mounted && widget.contentPlan?.planId != null) {
                      masterContentBloc.add(MasterContentFetch(
                        refresh: true,
                        planId: widget.contentPlan!.planId,
                      ));
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _updateButton() {
    return Padding(
      padding: ResponsiveBreakpoints.of(context).isMobile
          ? const EdgeInsets.all(10)
          : const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
      child: Row(
        children: [
          if (widget.contentPlan?.planId != null)
            Expanded(
              child: OutlinedButton(
                key: const Key("contentPlanDetailDelete"),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                child: const Text('Delete'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Content Plan'),
                        content: const Text(
                          'Are you sure you want to delete this content plan?',
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
                    _contentPlanBloc
                        .add(ContentPlanDelete(widget.contentPlan!));
                  }
                },
              ),
            ),
          if (widget.contentPlan?.planId != null) const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              key: const Key("contentPlanDetailSave"),
              child:
                  Text(widget.contentPlan?.planId == null ? 'Create' : 'Save'),
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) {
                  return;
                }

                updatedContentPlan = ContentPlan(
                  planId: widget.contentPlan?.planId,
                  pseudoId: _pseudoIdController.text.isEmpty
                      ? widget.contentPlan?.pseudoId
                      : _pseudoIdController.text,
                  personaId: _selectedPersona?.personaId,
                  weekStartDate: _weekStartDate,
                  theme: _themeController.text.isEmpty
                      ? null
                      : _themeController.text,
                );

                if (widget.contentPlan?.planId == null) {
                  // Create new content plan
                  _contentPlanBloc.add(ContentPlanCreate(updatedContentPlan));
                } else {
                  // Update existing content plan
                  _contentPlanBloc.add(ContentPlanUpdate(updatedContentPlan));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
