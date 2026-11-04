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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../blocs/pos_shift_bloc.dart';

/// Where this device remembers which till it is.
const posTerminalKey = 'posTerminal';

/// Shown instead of the till while it is closed.
class PosShiftOpenView extends StatefulWidget {
  const PosShiftOpenView({super.key, required this.terminalName});
  final String terminalName;

  @override
  PosShiftOpenViewState createState() => PosShiftOpenViewState();
}

class PosShiftOpenViewState extends State<PosShiftOpenView> {
  late final TextEditingController _terminalController;
  final _floatController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _terminalController = TextEditingController(text: widget.terminalName);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ListView(
          key: const Key('PosShiftOpenView'),
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              localizations.tillClosed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('posTerminalName'),
              controller: _terminalController,
              decoration: InputDecoration(labelText: localizations.till),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('posOpeningFloat'),
              controller: _floatController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: localizations.openingFloat,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('posOpenShift'),
              onPressed: () async {
                final bloc = context.read<PosShiftBloc>();
                final terminalName = _terminalController.text.trim();
                final openingFloat = Decimal.tryParse(_floatController.text);
                if (terminalName.isEmpty || openingFloat == null) return;
                await PersistFunctions.persistKeyValue(
                  posTerminalKey,
                  terminalName,
                );
                bloc.add(
                  PosShiftOpen(
                    terminalName: terminalName,
                    openingFloat: openingFloat,
                  ),
                );
              },
              child: Text(localizations.openTill),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _floatController.dispose();
    super.dispose();
  }
}

/// Cash into or out of the drawer that is no sale.
class PosCashMovementDialog extends StatefulWidget {
  const PosCashMovementDialog({super.key});

  @override
  PosCashMovementDialogState createState() => PosCashMovementDialogState();
}

class PosCashMovementDialogState extends State<PosCashMovementDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isIn = false;

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Dialog(
      key: const Key('PosCashMovementDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PosShiftBloc, PosShiftState>(
        listener: (context, state) {
          if (state.status == PosShiftStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == PosShiftStatus.success) {
            Navigator.of(context).pop();
          }
        },
        child: popUp(
          context: context,
          title: localizations.cashMovement,
          height: 360,
          width: 360,
          child: ListView(
            key: const Key('listView'),
            children: [
              SegmentedButton<bool>(
                key: const Key('posMovementDirection'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      localizations.cashOut,
                      key: const Key('posMovementOut'),
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      localizations.cashIn,
                      key: const Key('posMovementIn'),
                    ),
                  ),
                ],
                selected: {_isIn},
                onSelectionChanged: (selection) =>
                    setState(() => _isIn = selection.first),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('posMovementAmount'),
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: localizations.amount),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('posMovementReason'),
                controller: _reasonController,
                decoration: InputDecoration(labelText: localizations.reason),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('posMovementSave'),
                onPressed: () {
                  final amount = Decimal.tryParse(_amountController.text);
                  if (amount == null || amount <= Decimal.zero) return;
                  context.read<PosShiftBloc>().add(
                    PosCashMovementAdd(
                      amount: _isIn ? amount : -amount,
                      reason: _reasonController.text,
                    ),
                  );
                },
                child: Text(localizations.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

/// Count the drawer and end the shift. What should be there stays hidden until
/// the count is in.
class PosShiftCloseDialog extends StatefulWidget {
  const PosShiftCloseDialog({super.key});

  @override
  PosShiftCloseDialogState createState() => PosShiftCloseDialogState();
}

class PosShiftCloseDialogState extends State<PosShiftCloseDialog> {
  final _countedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Dialog(
      key: const Key('PosShiftCloseDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PosShiftBloc, PosShiftState>(
        listener: (context, state) {
          if (state.status == PosShiftStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == PosShiftStatus.success) {
            Navigator.of(context).pop();
          }
        },
        child: popUp(
          context: context,
          title: localizations.closeTill,
          height: 260,
          width: 360,
          child: ListView(
            key: const Key('listView'),
            children: [
              TextField(
                key: const Key('posCountedCash'),
                controller: _countedController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: localizations.countedCash,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('posCloseConfirm'),
                onPressed: () {
                  final counted = Decimal.tryParse(_countedController.text);
                  if (counted == null) return;
                  context.read<PosShiftBloc>().add(PosShiftClose(counted));
                },
                child: Text(localizations.closeTill),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countedController.dispose();
    super.dispose();
  }
}
