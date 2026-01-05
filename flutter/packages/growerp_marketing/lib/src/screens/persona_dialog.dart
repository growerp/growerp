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

/// Dialog for creating or editing a Marketing Persona
class PersonaDialog extends StatefulWidget {
  final Persona? persona;

  const PersonaDialog({super.key, this.persona});

  @override
  PersonaDialogState createState() => PersonaDialogState();
}

class PersonaDialogState extends State<PersonaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pseudoIdController;
  late TextEditingController _nameController;
  late TextEditingController _demographicsController;
  late TextEditingController _painPointsController;
  late TextEditingController _goalsController;
  late TextEditingController _toneOfVoiceController;
  late PersonaBloc _personaBloc;

  @override
  void initState() {
    super.initState();
    _personaBloc = context.read<PersonaBloc>();
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
  }

  @override
  void dispose() {
    _pseudoIdController.dispose();
    _nameController.dispose();
    _demographicsController.dispose();
    _painPointsController.dispose();
    _goalsController.dispose();
    _toneOfVoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Dialog(
      key: const Key('PersonaDialog'),
      insetPadding: EdgeInsets.all(isPhone ? 10 : 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: popUp(
        context: context,
        title: widget.persona == null ? 'New Persona' : 'Edit Persona',
        width: isPhone ? 400 : 600,
        height: isPhone ? 600 : 700,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('pseudoId'),
                  controller: _pseudoIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    hintText: 'Leave empty to auto-generate',
                    
                  ),
                  enabled:
                      widget.persona == null, // Only editable when creating
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('name'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Persona Name *',
                    hintText: 'e.g., Alex Johnson',
                    
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a persona name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('demographics'),
                  controller: _demographicsController,
                  decoration: const InputDecoration(
                    labelText: 'Demographics',
                    hintText: 'Age, occupation, location, etc.',
                    
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('painPoints'),
                  controller: _painPointsController,
                  decoration: const InputDecoration(
                    labelText: 'Pain Points',
                    hintText: 'What challenges does this persona face?',
                    
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('goals'),
                  controller: _goalsController,
                  decoration: const InputDecoration(
                    labelText: 'Goals',
                    hintText: 'What does this persona want to achieve?',
                    
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('toneOfVoice'),
                  controller: _toneOfVoiceController,
                  decoration: const InputDecoration(
                    labelText: 'Tone of Voice',
                    hintText: 'e.g., Professional yet approachable',
                    
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const Key('cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: const Key('save'),
                      onPressed: _savePersona,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _savePersona() {
    if (_formKey.currentState!.validate()) {
      final persona = Persona(
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
        goals: _goalsController.text.isEmpty ? null : _goalsController.text,
        toneOfVoice: _toneOfVoiceController.text.isEmpty
            ? null
            : _toneOfVoiceController.text,
      );

      if (widget.persona == null) {
        _personaBloc.add(PersonaCreate(persona));
      } else {
        _personaBloc.add(PersonaUpdate(persona));
      }

      Navigator.of(context).pop();
    }
  }
}
