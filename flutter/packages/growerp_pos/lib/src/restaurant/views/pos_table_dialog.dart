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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../blocs/pos_floor_bloc.dart';

/// Add or change a table. place puts a new table on the next free spot.
class PosTableDialog extends StatefulWidget {
  const PosTableDialog(this.table, {super.key, required this.place});
  final PosTable? table;
  final int place;

  @override
  PosTableDialogState createState() => PosTableDialogState();
}

class PosTableDialogState extends State<PosTableDialog> {
  final _nameController = TextEditingController();
  final _seatsController = TextEditingController();
  final _areaController = TextEditingController();
  String _shape = 'square';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.table?.tableName ?? '';
    _seatsController.text = '${widget.table?.seats ?? 4}';
    _areaController.text = widget.table?.areaName ?? '';
    _shape = widget.table?.shape ?? 'square';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    final isNew = widget.table == null;
    return Dialog(
      key: const Key('PosTableDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PosFloorBloc, PosFloorState>(
        listener: (context, state) {
          if (state.status == PosFloorStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == PosFloorStatus.success && state.message != null) {
            Navigator.of(context).pop();
          }
        },
        child: popUp(
          context: context,
          title: isNew ? localizations.newTable : localizations.table,
          height: 440,
          width: 360,
          child: ListView(
            key: const Key('listView'),
            children: [
              TextField(
                key: const Key('posTableName'),
                controller: _nameController,
                decoration: InputDecoration(labelText: localizations.name),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('posTableSeats'),
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: localizations.seats),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('posTableArea'),
                controller: _areaController,
                decoration: InputDecoration(labelText: localizations.area),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                key: const Key('posTableShape'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'square', icon: Icon(Icons.crop_square)),
                  ButtonSegment(
                    value: 'round',
                    icon: Icon(Icons.circle_outlined),
                  ),
                ],
                selected: {_shape},
                onSelectionChanged: (selection) =>
                    setState(() => _shape = selection.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!isNew) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('posTableDelete'),
                        onPressed: () => context.read<PosFloorBloc>().add(
                          PosTableDelete(widget.table!.assetId!),
                        ),
                        child: Text(localizations.delete),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('posTableSave'),
                      onPressed: () {
                        if (_nameController.text.trim().isEmpty) return;
                        context.read<PosFloorBloc>().add(
                          PosTableSave(
                            (widget.table ??
                                    PosTable(
                                      x: widget.place % 5,
                                      y: widget.place ~/ 5,
                                    ))
                                .copyWith(
                                  tableName: _nameController.text.trim(),
                                  seats: int.tryParse(_seatsController.text),
                                  areaName: _areaController.text.trim(),
                                  shape: _shape,
                                ),
                          ),
                        );
                      },
                      child: Text(localizations.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seatsController.dispose();
    _areaController.dispose();
    super.dispose();
  }
}
