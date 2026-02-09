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

import '../bloc/content_plan_bloc.dart';
import '../bloc/content_plan_event.dart';
import '../bloc/content_plan_state.dart';
import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';
import 'content_plan_detail_screen.dart';
import 'content_plan_list_styled_data.dart';

/// List screen for Content Plans
class ContentPlanList extends StatefulWidget {
  const ContentPlanList({super.key});

  @override
  ContentPlanListState createState() => ContentPlanListState();
}

class ContentPlanListState extends State<ContentPlanList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late ContentPlanBloc _contentPlanBloc;
  List<ContentPlan> contentPlans = const <ContentPlan>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;
  String searchString = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _contentPlanBloc = context.read<ContentPlanBloc>()
      ..add(const ContentPlanFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = contentPlans.map((plan) {
        final index = contentPlans.indexOf(plan);
        return getContentPlanListRow(
          context: context,
          plan: plan,
          index: index,
          bloc: _contentPlanBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getContentPlanListColumns(context),
        rows: rows,
        isLoading: _isLoading && contentPlans.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('contentPlanDetailScreen'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _contentPlanBloc,
                  child: ContentPlanDetailScreen(
                    contentPlan: contentPlans[index],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<ContentPlanBloc, ContentPlanState>(
      listener: (context, state) {
        if (state.status == ContentPlanStatus.failure) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.red,
          );
        }
        if (state.status == ContentPlanStatus.success) {
          if ((state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        }
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == ContentPlanStatus.loading;

        if (state.status == ContentPlanStatus.failure && contentPlans.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load content plans!',
          );
        }

        contentPlans = state.contentPlans;
        if (contentPlans.isNotEmpty && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(currentScroll);
              }
            });
          });
        }
        hasReachedMax = state.hasReachedMax;

        return Column(
          children: [
            // Filter bar with search
            ListFilterBar(
              searchHint: 'Search content plans...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _contentPlanBloc.add(
                  ContentPlanFetch(refresh: true, searchString: value),
                );
              },
            ),
            // Main content area with StyledDataTable
            Expanded(
              child: Stack(
                children: [
                  tableView(),
                  Positioned(
                    right: right,
                    bottom: bottom,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          right = right! - details.delta.dx;
                          bottom -= details.delta.dy;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            key: const Key('addNewContentPlan'),
                            heroTag: 'contentPlanBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _contentPlanBloc,
                                    child: const ContentPlanDetailScreen(
                                        contentPlan: null),
                                  );
                                },
                              );
                            },
                            tooltip: 'Add new content plan',
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            key: const Key('generateAIContentPlan'),
                            heroTag: 'contentPlanBtn2',
                            onPressed: () async {
                              if (!mounted) return;
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return BlocProvider.value(
                                    value: _contentPlanBloc,
                                    child: const GenerateContentPlanDialog(),
                                  );
                                },
                              );
                            },
                            tooltip: 'Generate Content Plan with AI',
                            child: const Icon(Icons.auto_awesome),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    currentScroll = _scrollController.offset;
    if (_isBottom && !hasReachedMax) {
      _contentPlanBloc.add(
        ContentPlanFetch(start: contentPlans.length, searchString: searchString),
      );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

/// Dialog for generating content plan with AI
class GenerateContentPlanDialog extends StatefulWidget {
  const GenerateContentPlanDialog({super.key});

  @override
  GenerateContentPlanDialogState createState() =>
      GenerateContentPlanDialogState();
}

class GenerateContentPlanDialogState extends State<GenerateContentPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _weekStartDate;
  Persona? _selectedPersona;
  late ContentPlanBloc _contentPlanBloc;

  @override
  void initState() {
    super.initState();
    _contentPlanBloc = context.read<ContentPlanBloc>();
    // Fetch personas for dropdown
    context
        .read<PersonaBloc>()
        .add(const PersonaFetch(refresh: true, limit: 100));
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('GenerateContentPlanDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Generate Content Plan with AI',
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<PersonaBloc, PersonaState>(
                  builder: (context, personaState) {
                    return DropdownButtonFormField<Persona>(
                      key: const Key('personaId'),
                      decoration: const InputDecoration(
                        labelText: 'Select Persona *',
                        hintText: 'Choose a persona to generate content for',
                      ),
                      initialValue: _selectedPersona,
                      isExpanded: true,
                      items: personaState.personas.map((persona) {
                        return DropdownMenuItem<Persona>(
                          value: persona,
                          child: Text(
                            '${persona.name} (${persona.pseudoId ?? "N/A"})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (Persona? newValue) {
                        setState(() {
                          _selectedPersona = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a persona';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Week Start Date (Optional)',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _weekStartDate != null
                              ? _weekStartDate.toString().substring(0, 10)
                              : 'Select a date',
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocConsumer<ContentPlanBloc, ContentPlanState>(
                  listener: (context, state) {
                    if (state.status == ContentPlanStatus.success &&
                        state.message != null &&
                        state.message!.contains('AI')) {
                      Navigator.of(context).pop();
                    }
                    if (state.status == ContentPlanStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Failed to generate content plan',
                        Colors.red,
                      );
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton.icon(
                      key: const Key('generateButton'),
                      onPressed: state.status == ContentPlanStatus.loading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() == true) {
                                _contentPlanBloc.add(
                                  ContentPlanGenerateWithAI(
                                    personaId: _selectedPersona!.personaId!,
                                    weekStartDate: _weekStartDate,
                                  ),
                                );
                              }
                            },
                      icon: state.status == ContentPlanStatus.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        state.status == ContentPlanStatus.loading
                            ? 'Generating...'
                            : 'Generate Content Plan',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
