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

import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';
import 'persona_detail_screen.dart';
import 'persona_list_styled_data.dart';

/// List screen for Marketing Personas
class PersonaList extends StatefulWidget {
  const PersonaList({super.key});

  @override
  PersonaListState createState() => PersonaListState();
}

class PersonaListState extends State<PersonaList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late PersonaBloc _personaBloc;
  List<Persona> personas = const <Persona>[];
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
    _personaBloc = context.read<PersonaBloc>()
      ..add(const PersonaFetch(refresh: true));
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    right = right ?? (isPhone ? 20 : 50);

    Widget tableView() {
      // Build rows for StyledDataTable
      final rows = personas.map((persona) {
        final index = personas.indexOf(persona);
        return getPersonaListRow(
          context: context,
          persona: persona,
          index: index,
          bloc: _personaBloc,
        );
      }).toList();

      return StyledDataTable(
        columns: getPersonaListColumns(context),
        rows: rows,
        isLoading: _isLoading && personas.isEmpty,
        scrollController: _scrollController,
        rowHeight: isPhone ? 72 : 56,
        onRowTap: (index) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return Dismissible(
                key: const Key('personaDetailScreen'),
                direction: DismissDirection.startToEnd,
                child: BlocProvider.value(
                  value: _personaBloc,
                  child: PersonaDetailScreen(persona: personas[index]),
                ),
              );
            },
          );
        },
      );
    }

    return BlocConsumer<PersonaBloc, PersonaState>(
      listener: (context, state) {
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
      },
      builder: (context, state) {
        // Update loading state
        _isLoading = state.status == PersonaStatus.loading;

        if (state.status == PersonaStatus.failure && personas.isEmpty) {
          return const FatalErrorForm(
            message: 'Could not load personas!',
          );
        }

        personas = state.personas;
        if (personas.isNotEmpty && _scrollController.hasClients) {
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
              searchHint: 'Search personas...',
              searchController: _searchController,
              onSearchChanged: (value) {
                searchString = value;
                _personaBloc.add(
                  PersonaFetch(refresh: true, searchString: value),
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
                            key: const Key('addNewPersona'),
                            heroTag: 'personaBtn1',
                            onPressed: () async {
                              await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                    value: _personaBloc,
                                    child: const PersonaDetailScreen(
                                        persona: null),
                                  );
                                },
                              );
                            },
                            tooltip: 'Add new persona',
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            key: const Key('generateAIPersona'),
                            heroTag: 'personaBtn2',
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
      _personaBloc.add(
        PersonaFetch(start: personas.length, searchString: searchString),
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
