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

import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';
import 'persona_detail_screen.dart';
import 'persona_list_table_def.dart';

// Table padding and background decoration
const personaPadding = SpanPadding(trailing: 5, leading: 5);

SpanDecoration? getPersonaBackGround(BuildContext context, int index) {
  return index == 0
      ? SpanDecoration(color: Theme.of(context).colorScheme.tertiaryContainer)
      : null;
}

/// List screen for Marketing Personas
class PersonaList extends StatefulWidget {
  const PersonaList({super.key});

  @override
  PersonaListState createState() => PersonaListState();
}

class PersonaListState extends State<PersonaList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  final double _scrollThreshold = 100.0;
  late PersonaBloc _personaBloc;
  List<Persona> personas = const <Persona>[];
  bool hasReachedMax = false;
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _personaBloc = context.read<PersonaBloc>()
      ..add(const PersonaFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);

    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          if (personas.isEmpty) {
            return const Center(
              child: Text(
                'No personas found',
                style: TextStyle(fontSize: 20.0),
              ),
            );
          }

          // get table data formatted for tableView
          var (
            List<List<TableViewCell>> tableViewCells,
            List<double> fieldWidths,
            double? rowHeight,
          ) = get2dTableData<Persona>(
            getPersonaListTableData,
            bloc: _personaBloc,
            classificationId: 'AppAdmin',
            context: context,
            items: personas,
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
                    padding: personaPadding,
                    backgroundDecoration: getPersonaBackGround(
                      context,
                      index,
                    ),
                    extent: FixedTableSpanExtent(fieldWidths[index]),
                  ),
            pinnedColumnCount: 1,
            rowBuilder: (index) => index >= tableViewCells.length
                ? null
                : TableSpan(
                    padding: personaPadding,
                    backgroundDecoration: getPersonaBackGround(
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
                                return index > personas.length
                                    ? const BottomLoader()
                                    : Dismissible(
                                        key: const Key('personaDetailScreen'),
                                        direction: DismissDirection.startToEnd,
                                        child: BlocProvider.value(
                                          value: _personaBloc,
                                          child: PersonaDetailScreen(
                                            persona: personas[index - 1],
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
          if (state.status == PersonaStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
          }
          if (state.status == PersonaStatus.success) {
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
          if (state.status == PersonaStatus.failure) {
            return const FatalErrorForm(
              message: "Could not load personas!",
            );
          } else {
            personas = state.personas;
            if (personas.isNotEmpty && _scrollController.hasClients) {
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
                          heroTag: "personaBtn1",
                          onPressed: () async {
                            // find persona id to show
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _personaBloc,
                                  child: const SearchPersonaDialog(),
                                );
                              },
                            ).then(
                              (value) async => value != null
                                  ? await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                          value: _personaBloc,
                                          child: PersonaDetailScreen(
                                            persona: value,
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
                          key: const Key("addNewPersona"),
                          heroTag: "personaBtn2",
                          onPressed: () async {
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return BlocProvider.value(
                                  value: _personaBloc,
                                  child:
                                      const PersonaDetailScreen(persona: null),
                                );
                              },
                            );
                          },
                          tooltip: 'Add new persona',
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          key: const Key("generateAIPersona"),
                          heroTag: "personaBtn3",
                          onPressed: () async {
                            if (!mounted) return;
                            await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return BlocProvider.value(
                                  value: _personaBloc,
                                  child: const GeneratePersonaDialog(),
                                );
                              },
                            );
                          },
                          tooltip: 'Generate Persona with AI',
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

        return BlocConsumer<PersonaBloc, PersonaState>(
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
      _personaBloc.add(
        PersonaFetch(
          start: personas.length,
        ),
      );
    }
  }
}

/// Search dialog for personas
class SearchPersonaDialog extends StatefulWidget {
  const SearchPersonaDialog({super.key});

  @override
  SearchPersonaDialogState createState() => SearchPersonaDialogState();
}

class SearchPersonaDialogState extends State<SearchPersonaDialog> {
  final TextEditingController searchBoxController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  late PersonaBloc _personaBloc;

  @override
  void initState() {
    super.initState();
    _personaBloc = context.read<PersonaBloc>();
  }

  @override
  void dispose() {
    searchBoxController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _personaBloc.add(const PersonaSearchRequested(searchString: ''));
      return;
    }
    _personaBloc.add(PersonaSearchRequested(searchString: query));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('SearchPersonaDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Search Personas',
        child: Column(
          children: [
            TextField(
              key: const Key('searchField'),
              controller: searchBoxController,
              focusNode: searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search by ID or Name',
                hintText: 'Enter persona ID or name',
                
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
              child: BlocBuilder<PersonaBloc, PersonaState>(
                builder: (context, state) {
                  if (state.searchStatus == PersonaStatus.loading) {
                    return const LoadingIndicator();
                  }
                  if (state.searchStatus == PersonaStatus.failure) {
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
                        : 'No personas matched your search.';
                    return Center(child: Text(message));
                  }
                  return ListView.builder(
                    itemCount: state.searchResults.length,
                    itemBuilder: (context, index) {
                      final persona = state.searchResults[index];
                      return ListTile(
                        key: Key('personaSearchItem$index'),
                        leading: persona.pseudoId != null
                            ? CircleAvatar(
                                child: Text(
                                  persona.pseudoId!
                                      .substring(0, 2)
                                      .toUpperCase(),
                                ),
                              )
                            : null,
                        title: Text(persona.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (persona.pseudoId != null)
                              Text('ID: ${persona.pseudoId}'),
                            if (persona.demographics != null)
                              Text(
                                persona.demographics!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(persona),
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

/// Dialog for generating persona with AI
class GeneratePersonaDialog extends StatefulWidget {
  const GeneratePersonaDialog({super.key});

  @override
  GeneratePersonaDialogState createState() => GeneratePersonaDialogState();
}

class GeneratePersonaDialogState extends State<GeneratePersonaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();
  final _targetMarketController = TextEditingController();
  late PersonaBloc _personaBloc;

  @override
  void initState() {
    super.initState();
    _personaBloc = context.read<PersonaBloc>();
  }

  @override
  void dispose() {
    _businessController.dispose();
    _targetMarketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('GeneratePersonaDialog'),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: 'Generate Persona with AI',
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('businessDescription'),
                controller: _businessController,
                decoration: const InputDecoration(
                  labelText: 'Business Description *',
                  hintText: 'Describe your business...',
                  
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a business description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('targetMarket'),
                controller: _targetMarketController,
                decoration: const InputDecoration(
                  labelText: 'Target Market (Optional)',
                  hintText: 'Who is your target customer?',
                  
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    key: const Key('generateButton'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _personaBloc.add(PersonaGenerateWithAI(
                          businessDescription: _businessController.text,
                          targetMarket: _targetMarketController.text.isEmpty
                              ? null
                              : _targetMarketController.text,
                        ));
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
