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

import '../liner_type.dart';

class LinerTypeDialog extends StatefulWidget {
  final LinerType linerType;
  const LinerTypeDialog(this.linerType, {super.key});
  @override
  LinerTypeDialogState createState() => LinerTypeDialogState();
}

class LinerTypeDialogState extends State<LinerTypeDialog> {
  late LinerType linerType;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _widthIncrementController = TextEditingController();
  final _linerWeightController = TextEditingController();
  final _rollStockWidthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    linerType = widget.linerType;
    _nameController.text = linerType.linerName ?? '';
    _widthIncrementController.text = linerType.widthIncrement?.toString() ?? '';
    _linerWeightController.text = linerType.linerWeight?.toString() ?? '';
    _rollStockWidthController.text = linerType.rollStockWidth?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('LinerTypeDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<LinerTypeBloc, LinerTypeState>(
        listener: (context, state) {
          switch (state.status) {
            case LinerTypeStatus.success:
              HelperFunctions.showMessage(
                context,
                linerType.linerTypeId.isEmpty
                    ? 'Add successful'
                    : 'Update successful',
                Colors.green,
              );
              Navigator.of(context).pop();
              break;
            case LinerTypeStatus.failure:
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
          title: linerType.linerTypeId.isEmpty
              ? 'New Liner Type'
              : 'Liner Type: ${linerType.linerName ?? linerType.linerTypeId}',
          height: 500,
          width: 450,
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
            TextFormField(
              key: const Key('linerName'),
              decoration: const InputDecoration(labelText: 'Liner Name'),
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a liner name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('widthIncrement'),
              decoration: const InputDecoration(
                  labelText: 'Width Increment (ft)', hintText: 'e.g. 12.5'),
              controller: _widthIncrementController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('rollStockWidth'),
              decoration: const InputDecoration(
                  labelText: 'Roll Stock Width (ft)', hintText: 'e.g. 22.5'),
              controller: _rollStockWidthController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('linerWeight'),
              decoration: const InputDecoration(
                  labelText: 'Liner Weight (lb/sqft)', hintText: 'e.g. 0.63'),
              controller: _linerWeightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              key: const Key('update'),
              child: Text(linerType.linerTypeId.isEmpty ? 'Add' : 'Update'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<LinerTypeBloc>().add(
                    LinerTypeUpdate(
                      LinerType(
                        linerTypeId: linerType.linerTypeId,
                        linerName: _nameController.text,
                        widthIncrement:
                            Decimal.tryParse(_widthIncrementController.text),
                        linerWeight:
                            Decimal.tryParse(_linerWeightController.text),
                        rollStockWidth:
                            Decimal.tryParse(_rollStockWidthController.text),
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
    _nameController.dispose();
    _widthIncrementController.dispose();
    _linerWeightController.dispose();
    _rollStockWidthController.dispose();
    super.dispose();
  }
}
