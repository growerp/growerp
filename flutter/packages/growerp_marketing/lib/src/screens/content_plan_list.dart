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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../bloc/content_plan_bloc.dart';
import '../bloc/content_plan_event.dart';
import '../bloc/content_plan_state.dart';
import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';
import 'content_plan_detail_screen.dart';
import 'content_plan_list_table_def.dart';

// Table padding and background decoration
const contentPlanPadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getContentPlanBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

/// List screen for Content Plans
class ContentPlanList extends StatefulWidget {
  const ContentPlanList({super.key});

  @override
  ContentPlanListState createState() => ContentPlanListState();
}

class ContentPlanListState extends State<ContentPlanList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late ContentPlanBloc _contentPlanBloc;
  List<ContentPlan> contentPlans = const <ContentPlan>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

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
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (contentPlans.isEmpty) {
            return const Center(
              child: Text(
                'No content plans found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<ContentPlan>(
            getContentPlanListTableData,
            bloc: _contentPlanBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: contentPlans,
          );

          return TableView.builder(
            diagonalDragBehavior: DiagonalDragBehavior.free,
            verticalDetails: ScrollableDetails.vertical(
              controller: _scrollController,
            ),
            horizontalDetails: ScrollableDetails.horizontal(
              controller: _horizontalController,
            ),
            cellBuilder: (context, vicinity) =>
                tableViewCells[vicinity.row][vicinity.column],
            columnBuilder: (index) => index >= tableViewCells[0].length
                ? null
                : TableSpan(
                    padding: contentPlanPadding,
                    backgroundDecoration: getContentPlanBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: contentPlanPadding,
                    backgroundDecoration: getContentPlanBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(rowHeight!),
                    recognizerFactories: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                        (TapGestureRecognizer t) => t.onTap = () => showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return index > contentPlans.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: const Key(
                                            'contentPlanDetailScreen'),
                                        direction: DismissDirection.startToEnd,
                                        child: BlocProvider.value(
                                          value: _contentPlanBloc,
                                          child: ContentPlanDetailScreen(
                                            contentPlan:
                                                contentPlans[index - 1],
                                          ),
                                        ),
                                      );
                              },
                            ),
                      ),
                    },
                  ),
            pinnedRowCount: 1,
          );
        }

        blocListener(context, state) {
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
        }

        blocBuilder(context, state) {
          if (state.status == ContentPlanStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load content plans!",
            );
          } else {
            contentPlans = state.contentPlans;
            if (contentPlans.isNotEmpty && _scrollController.hasClients) {
              Future.delayed(const Duration(milliseconds: 100), () {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(currentScroll);
                    }
                  },
                );
              });
            }
            hasReachedMax = state.hasReachedMax;
            return Stack(
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
                      children: [
                        FloatingActionButton(
                          key: const Key("search"),
                          heroTag: "contentPlanBtn1",
                          onPressed: () async {
                            // find content plan id to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _contentPlanBloc,
                                  child: const SearchContentPlanDialog(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _contentPlanBloc,
                                          child: ContentPlanDetailScreen(
                                            contentPlan: value,
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                          child: const Icon(Icons.search),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          key: const Key("addNewContentPlan"),
                          heroTag: "contentPlanBtn2",
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
                          key: const Key("generateAIContentPlan"),
                          heroTag: "contentPlanBtn3",
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
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        }

        return BlocConsumer<ContentPlanBloc, ContentPlanState>(
          listener: blocListener,
          builder: blocBuilder,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the controller is attached before accessing position properties
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    currentScroll = _scrollController.position.pixels;
    if (!hasReachedMax &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _scrollThreshold) {
      _contentPlanBloc.add(
        ContentPlanFetch(
          start: contentPlans.length,
        ),
      );
    }
  }
}

/// Search dialog for content plans
class SearchContentPlanDialog extends StatefulWidget {
  const SearchContentPlanDialog({super.key});

  @override
  SearchContentPlanDialogState createState() => SearchContentPlanDialogState();
}

class SearchContentPlanDialogState extends State<SearchContentPlanDialog> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late ContentPlanBloc _contentPlanBloc;

  @override
  void initState() {
    super.initState();
    _contentPlanBloc = context.read<ContentPlanBloc>();
  }

  @override
  void dispose() {
    searchBoxController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _contentPlanBloc.add(const ContentPlanSearchRequested(searchString: ''));
      return;
    }
    _contentPlanBloc.add(ContentPlanSearchRequested(searchString: query));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('SearchContentPlanDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Content Plans',
        child: Column(
          children: [
            TextField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search by ID or Theme',
                hintText: 'Enter content plan ID or theme',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchBoxController.clear();
                    _performSearch('');
                  },
                ),
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<ContentPlanBloc, ContentPlanState>(
                builder: (context, state) {
                  if (state.searchStatus == ContentPlanStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (state.searchStatus == ContentPlanStatus.failure) {
                    return Center(
                      child: Text(
                        state.searchError ?? 'Search failed',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (state.searchResults.isEmpty) {
                    final message = searchBoxController.text.isEmpty
                        ? 'Enter a search term to begin.'
                        : 'No content plans matched your search.';
                    return Center(child: Text(message));
                  }
                  return ListView.builder(
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final contentPlan = state.searchResults[index];
                      return ListTile(
                        key: Key('contentPlanSearchItem$index'),
                        leading: contentPlan.pseudoId != null
                            ? CircleAvatar(
                                child: Text(
                                  contentPlan.pseudoId!
                                      .substring(0, 2)
                                      .toUpperCase(),
                                ),
                              )
                            : null,
                        title: Text(contentPlan.theme ?? 'No theme'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contentPlan.pseudoId != null)
                              Text('ID: ${contentPlan.pseudoId}'),
                            if (contentPlan.weekStartDate != null)
                              Text(
                                'Week of: ${contentPlan.weekStartDate.toString().substring(0, 10)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(contentPlan),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
