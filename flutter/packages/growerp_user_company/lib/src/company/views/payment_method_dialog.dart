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
import 'package:credit_card_validator/credit_card_validator.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class PaymentMethodDialog extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  const PaymentMethodDialog({super.key, this.paymentMethod});
  @override
  PaymentMethodDialogState createState() => PaymentMethodDialogState();
}

class PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final TextEditingController _creditCardNumberController =
      TextEditingController();
  final TextEditingController _expireMonthController = TextEditingController();
  final TextEditingController _expireYearController = TextEditingController();
  late CreditCardType _cardType;
  final CreditCardValidator _ccValidator = CreditCardValidator();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cardType = (widget.paymentMethod?.creditCardType ??
        CreditCardType.getByValue(''))!;
    _creditCardNumberController.text =
        widget.paymentMethod?.creditCardNumber ?? '';
    _expireMonthController.text = widget.paymentMethod?.expireMonth ?? '';
    _expireYearController.text = widget.paymentMethod?.expireYear ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        key: const Key('PaymentMethodDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            height: 450,
            width: 350,
            title: 'PaymentMethod',
            child: _editPaymentMethod(context)));
  }

  Widget _editPaymentMethod(BuildContext context) {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            key: const Key('listView'),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                Visibility(
                  visible: widget.paymentMethod?.ccDescription != null,
                  child: Text("${widget.paymentMethod?.ccDescription}",
                      key: const Key('regCard')),
                ),
                const Text("New Card:",
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<CreditCardType>(
                  key: const Key('cardTypeDropDown'),
                  decoration: const InputDecoration(labelText: 'Card Type'),
                  hint: const Text('Card Type'),
                  value: _cardType,
                  validator: (value) => value == null ? 'field required' : null,
                  items: CreditCardType.values
                      .map((item) => DropdownMenuItem<CreditCardType>(
                            value: item,
                            child: Text(item.value),
                          ))
                      .toList(),
                  onChanged: (CreditCardType? newValue) {
                    setState(() {
                      _cardType = newValue!;
                    });
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('creditCardNumber'),
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  controller: _creditCardNumberController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Credit Card Number?';
                    }
                    var valid = _ccValidator.validateCCNum(value);
                    if (!valid.isPotentiallyValid) {
                      return 'Card Number not a valid number!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('expireMonth'),
                      decoration:
                          const InputDecoration(labelText: 'Expire Month'),
                      controller: _expireMonthController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter expiration month?';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      key: const Key('expireYear'),
                      decoration:
                          const InputDecoration(labelText: 'Expire Year'),
                      controller: _expireYearController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a expiration year?';
                        }
                        return null;
                      },
                    ),
                  )
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          key: const Key('updatePaymentMethod'),
                          child: Text(
                              widget.paymentMethod?.creditCardNumber != null
                                  ? 'Update'
                                  : 'Add'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.of(context).pop(PaymentMethod(
                                ccDescription: _cardType.toString(),
                                creditCardType: _cardType,
                                creditCardNumber:
                                    _creditCardNumberController.text,
                                expireMonth: _expireMonthController.text,
                                expireYear: _expireYearController.text,
                              ));
                            }
                          }))
                ]),
              ],
            )));
  }
}
