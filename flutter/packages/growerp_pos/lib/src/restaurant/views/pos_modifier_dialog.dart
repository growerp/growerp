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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../l10n/generated/pos_localizations.dart';

/// What the guest chose.
class PosModifierChoice {
  const PosModifierChoice(this.modifierIds, this.note);
  final List<String> modifierIds;
  final String note;
}

/// Choose the modifiers of a product. Pops with the choice.
class PosModifierDialog extends StatefulWidget {
  const PosModifierDialog({
    super.key,
    required this.productName,
    required this.groups,
    required this.currencyId,
  });
  final String productName;
  final List<PosModifierGroup> groups;
  final String currencyId;

  @override
  PosModifierDialogState createState() => PosModifierDialogState();
}

class PosModifierDialogState extends State<PosModifierDialog> {
  final Set<String> _selected = {};
  final _noteController = TextEditingController();

  int _count(PosModifierGroup group) => group.modifiers
      .where((modifier) => _selected.contains(modifier.modifierId))
      .length;

  bool get _valid => widget.groups.every(
    (group) =>
        _count(group) >= (group.minSelect ?? 0) &&
        (group.maxSelect == null ||
            group.maxSelect == 0 ||
            _count(group) <= group.maxSelect!),
  );

  void _toggle(PosModifierGroup group, PosModifier modifier) {
    setState(() {
      if (_selected.remove(modifier.modifierId)) return;
      // a choice of one swaps instead of refusing
      if (group.maxSelect == 1) {
        _selected.removeAll(group.modifiers.map((m) => m.modifierId));
      }
      _selected.add(modifier.modifierId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Dialog(
      key: const Key('PosModifierDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: widget.productName,
        height: 520,
        width: 380,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('listView'),
                children: [
                  for (final group in widget.groups) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        group.groupName ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final modifier in group.modifiers)
                          FilterChip(
                            key: Key('posModifier${modifier.modifierName}'),
                            selected: _selected.contains(modifier.modifierId),
                            label: Text(
                              (modifier.priceDelta?.toDouble() ?? 0) == 0
                                  ? modifier.modifierName ?? ''
                                  : '${modifier.modifierName} +'
                                        '${modifier.priceDelta.currency(currencyId: widget.currencyId)}',
                            ),
                            onSelected: (_) => _toggle(group, modifier),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('posLineNote'),
                    controller: _noteController,
                    decoration: InputDecoration(labelText: localizations.note),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('posModifierAdd'),
                onPressed: _valid
                    ? () => Navigator.of(context).pop(
                        PosModifierChoice(
                          _selected.toList(),
                          _noteController.text,
                        ),
                      )
                    : null,
                child: Text(localizations.addToTab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
