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
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_insurance.dart';

/// Record a commission payment of the carrier on a policy; it is booked as a
/// sales invoice to the carrier.
class ReceiveCommissionDialog extends StatefulWidget {
  final Policy policy;
  const ReceiveCommissionDialog(this.policy, {super.key});
  @override
  ReceiveCommissionDialogState createState() => ReceiveCommissionDialogState();
}

class ReceiveCommissionDialogState extends State<ReceiveCommissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // suggest what is still outstanding of the yearly commission
    final outstanding =
        (widget.policy.commissionExpected ?? Decimal.zero) -
        (widget.policy.commissionReceived ?? Decimal.zero);
    if (outstanding > Decimal.zero) {
      _amountController.text = outstanding.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = InsuranceLocalizations.of(context)!;
    final policy = widget.policy;
    return Dialog(
      key: const Key('ReceiveCommissionDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<PolicyBloc, PolicyState>(
        listener: (context, state) {
          switch (state.status) {
            case PolicyStatusBloc.success:
              HelperFunctions.showMessage(
                context,
                localizations.commissionReceivedSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case PolicyStatusBloc.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title:
              '${localizations.receiveCommission} '
              '${policy.policyNumber ?? policy.pseudoId}',
          height: 400,
          width: 400,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const Key('listView'),
              children: [
                Text('${localizations.carrier}: ${policy.carrierName ?? ''}'),
                Text('${localizations.insured}: ${policy.insuredName ?? ''}'),
                Text(
                  '${localizations.commissionExpected}: '
                  '${policy.commissionExpected ?? ''}',
                  key: const Key('commissionExpected'),
                ),
                Text(
                  '${localizations.commissionReceived}: '
                  '${policy.commissionReceived ?? ''}',
                  key: const Key('commissionReceived'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('amount'),
                  decoration: InputDecoration(labelText: localizations.amount),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final amount = Decimal.tryParse(value ?? '');
                    return amount == null || amount <= Decimal.zero
                        ? localizations.fieldRequired
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('update'),
                  child: Text(localizations.receiveCommission),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    context.read<PolicyBloc>().add(
                      PolicyCommissionReceive(
                        policyId: policy.policyId,
                        amount: Decimal.parse(_amountController.text),
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
