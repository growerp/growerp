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
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/persona_bloc.dart';
import '../bloc/persona_event.dart';
import '../bloc/persona_state.dart';

class PersonaDetailScreen extends StatefulWidget {
  final Persona? persona;

  const PersonaDetailScreen({
    super.key,
    this.persona,
  });

  @override
  PersonaDetailScreenState createState() => PersonaDetailScreenState();
}

class PersonaDetailScreenState extends State<PersonaDetailScreen> {
  late ScrollController _scrollController;
  late bool isPhone;
  late double top;
  double? right;
  late bool isVisible;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _pseudoIdController;
  late TextEditingController _nameController;
  late TextEditingController _demographicsController;
  late TextEditingController _painPointsController;
  late TextEditingController _goalsController;
  late TextEditingController _toneOfVoiceController;

  late Persona updatedPersona;
  late PersonaBloc _personaBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    top = 250; // Start lower on the screen
    isVisible = true;

    // Initialize form controllers
    _pseudoIdController =
        TextEditingController(text: widget.persona?.pseudoId ?? '');
    _nameController = TextEditingController(text: widget.persona?.name ?? '');
    _demographicsController =
        TextEditingController(text: widget.persona?.demographics ?? '');
    _painPointsController =
        TextEditingController(text: widget.persona?.painPoints ?? '');
    _goalsController = TextEditingController(text: widget.persona?.goals ?? '');
    _toneOfVoiceController =
        TextEditingController(text: widget.persona?.toneOfVoice ?? '');

    updatedPersona = widget.persona ??
        const Persona(
          name: '',
        );
    _personaBloc = context.read<PersonaBloc>();

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
    _nameController.dispose();
    _demographicsController.dispose();
    _painPointsController.dispose();
    _goalsController.dispose();
    _toneOfVoiceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 40);

    return Dialog(
      key: Key('PersonaDetail${widget.persona?.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: "Marketing Persona #${widget.persona?.pseudoId ?? 'New'}",
        width: isPhone ? 400 : 800,
        height: isPhone ? 700 : 600,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                BlocConsumer<PersonaBloc, PersonaState>(
                  listener: (context, state) {
                    if (state.status == PersonaStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Error',
                        Colors.red,
                      );
                    }
                    if (state.status == PersonaStatus.success &&
                        state.message != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    if (state.status == PersonaStatus.loading) {
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

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('personaDetailListView'),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GroupingDecorator(
              labelText: 'Persona Information',
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
                        child: TextFormField(
                          key: const Key('name'),
                          decoration: const InputDecoration(
                            labelText: 'Persona Name *',
                            hintText: 'e.g., Alex Johnson',
                          ),
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a persona name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('demographics'),
                          decoration: const InputDecoration(
                            labelText: 'Demographics',
                            hintText: 'Age, occupation, location, etc.',
                          ),
                          controller: _demographicsController,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText: 'Pain Points & Goals',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('painPoints'),
                          decoration: const InputDecoration(
                            labelText: 'Pain Points',
                            hintText: 'What challenges does this persona face?',
                          ),
                          controller: _painPointsController,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('goals'),
                          decoration: const InputDecoration(
                            labelText: 'Goals',
                            hintText: 'What does this persona want to achieve?',
                          ),
                          controller: _goalsController,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText: 'Communication Style',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('toneOfVoice'),
                          decoration: const InputDecoration(
                            labelText: 'Tone of Voice',
                            hintText: 'e.g., Professional yet approachable',
                          ),
                          controller: _toneOfVoiceController,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _updateButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _updateButton() {
    return Padding(
      padding: ResponsiveBreakpoints.of(context).isMobile
          ? const EdgeInsets.all(10)
          : const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
      child: Row(
        children: [
          if (widget.persona?.personaId != null)
            Expanded(
              child: OutlinedButton(
                key: const Key("personaDetailDelete"),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                ),
                child: const Text('Delete'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Persona'),
                        content: const Text(
                          'Are you sure you want to delete this persona?',
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
                    _personaBloc.add(PersonaDelete(widget.persona!));
                  }
                },
              ),
            ),
          if (widget.persona?.personaId != null) const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              key: const Key("personaDetailSave"),
              child:
                  Text(widget.persona?.personaId == null ? 'Create' : 'Save'),
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) {
                  return;
                }

                updatedPersona = Persona(
                  personaId: widget.persona?.personaId,
                  pseudoId: _pseudoIdController.text.isEmpty
                      ? widget.persona?.pseudoId
                      : _pseudoIdController.text,
                  name: _nameController.text,
                  demographics: _demographicsController.text.isEmpty
                      ? null
                      : _demographicsController.text,
                  painPoints: _painPointsController.text.isEmpty
                      ? null
                      : _painPointsController.text,
                  goals: _goalsController.text.isEmpty
                      ? null
                      : _goalsController.text,
                  toneOfVoice: _toneOfVoiceController.text.isEmpty
                      ? null
                      : _toneOfVoiceController.text,
                );

                if (widget.persona?.personaId == null) {
                  // Create new persona
                  _personaBloc.add(PersonaCreate(updatedPersona));
                } else {
                  // Update existing persona
                  _personaBloc.add(PersonaUpdate(updatedPersona));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
