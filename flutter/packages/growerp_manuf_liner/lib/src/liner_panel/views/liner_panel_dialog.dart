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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../liner_panel.dart';
import '../../liner_type/liner_type.dart';

class LinerPanelDialog extends StatefulWidget {
  final LinerPanel linerPanel;
  const LinerPanelDialog(this.linerPanel, {super.key});
  @override
  LinerPanelDialogState createState() => LinerPanelDialogState();
}

class LinerPanelDialogState extends State<LinerPanelDialog> {
  late LinerPanel linerPanel;
  final _formKey = GlobalKey<FormState>();
  final _panelNameController = TextEditingController();
  final _panelWidthController = TextEditingController();
  final _panelLengthController = TextEditingController();
  String? _selectedLinerTypeId;

  @override
  void initState() {
    super.initState();
    linerPanel = widget.linerPanel;
    _panelNameController.text = linerPanel.panelName ?? '';
    _panelWidthController.text = linerPanel.panelWidth?.toString() ?? '';
    _panelLengthController.text = linerPanel.panelLength?.toString() ?? '';
    _selectedLinerTypeId = linerPanel.linerTypeId;
    // Fetch liner types so dropdown is populated
    context.read<LinerTypeBloc>().add(const LinerTypesFetch(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('LinerPanelDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<LinerPanelBloc, LinerPanelState>(
        listener: (context, state) {
          switch (state.status) {
            case LinerPanelStatus.success:
              HelperFunctions.showMessage(
                context,
                linerPanel.qcNum.isEmpty ? 'Panel added' : 'Panel updated',
                Colors.green,
              );
              Navigator.of(context).pop();
              break;
            case LinerPanelStatus.failure:
              HelperFunctions.showMessage(
                context,
                'Error: ${state.message ?? ''}',
                Colors.red,
              );
              break;
            default:
              break;
          }
        },
        child: popUp(
          context: context,
          child: _showForm(isPhone),
          title: linerPanel.qcNum.isEmpty
              ? 'New Panel'
              : 'Panel QC#${linerPanel.qcNum}',
          height: 520,
          width: 420,
        ),
      ),
    );
  }

  Widget _showForm(bool isPhone) {
    return Center(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('listView'),
          children: <Widget>[
            // Liner type dropdown
            BlocBuilder<LinerTypeBloc, LinerTypeState>(
              builder: (context, linerTypeState) {
                return DropdownButtonFormField<String>(
                  key: const Key('linerTypeDropdown'),
                  decoration: const InputDecoration(labelText: 'Liner Type'),
                  initialValue: _selectedLinerTypeId,
                  items: linerTypeState.linerTypes
                      .map((lt) => DropdownMenuItem<String>(
                            value: lt.linerTypeId,
                            child: Text(lt.linerName ?? lt.linerTypeId),
                          ))
                      .toList(),
                  onChanged: (value) => _selectedLinerTypeId = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a liner type';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('panelName'),
              decoration:
                  const InputDecoration(labelText: 'Panel Name (optional)'),
              controller: _panelNameController,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('panelWidth'),
              decoration:
                  const InputDecoration(labelText: 'Panel Width (ft)'),
              controller: _panelWidthController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter panel width';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('panelLength'),
              decoration:
                  const InputDecoration(labelText: 'Panel Length (ft)'),
              controller: _panelLengthController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter panel length';
                }
                return null;
              },
            ),
            // Read-only computed fields (existing panels only)
            if (linerPanel.qcNum.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: Text(
                    'SqFt: ${linerPanel.panelSqft ?? '—'}',
                    key: const Key('panelSqft'),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Passes: ${linerPanel.passes ?? '—'}',
                    key: const Key('passes'),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Weight: ${linerPanel.weight ?? '—'} lb',
                    key: const Key('weight'),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              key: const Key('update'),
              child: Text(linerPanel.qcNum.isEmpty ? 'Add' : 'Update'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<LinerPanelBloc>().add(
                    LinerPanelUpdate(
                      LinerPanel(
                        qcNum: linerPanel.qcNum,
                        workEffortId: linerPanel.workEffortId,
                        salesOrderId: linerPanel.salesOrderId,
                        linerTypeId: _selectedLinerTypeId,
                        panelName: _panelNameController.text.isNotEmpty
                            ? _panelNameController.text
                            : null,
                        panelWidth:
                            Decimal.tryParse(_panelWidthController.text),
                        panelLength:
                            Decimal.tryParse(_panelLengthController.text),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _panelNameController.dispose();
    _panelWidthController.dispose();
    _panelLengthController.dispose();
    super.dispose();
  }
}
