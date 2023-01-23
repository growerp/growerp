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
import '../../../domains/domains.dart';
import 'package:credit_card_validator/credit_card_validator.dart';

class PaymentMethodDialog extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  final Key? key;
  const PaymentMethodDialog({this.paymentMethod, this.key}) : super(key: key);
  @override
  _PaymentMethodState createState() => _PaymentMethodState(paymentMethod, key);
}

class _PaymentMethodState extends State<PaymentMethodDialog> {
  final PaymentMethod? paymentMethod;
  final Key? key;
  TextEditingController _creditCardNumberController = TextEditingController();
  TextEditingController _expireMonthController = TextEditingController();
  TextEditingController _expireYearController = TextEditingController();
  late CreditCardType _cardType;
  CreditCardValidator _ccValidator = CreditCardValidator();

  final _formKey = GlobalKey<FormState>();

  _PaymentMethodState(this.paymentMethod, this.key);

  @override
  void initState() {
    super.initState();
    _cardType = paymentMethod?.creditCardType ?? CreditCardType.tryParse('');
    _creditCardNumberController.text = paymentMethod?.creditCardNumber ?? '';
    _expireMonthController.text = paymentMethod?.expireMonth ?? '';
    _expireYearController.text = paymentMethod?.expireYear ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: GestureDetector(
            onTap: () {},
            child: Dialog(
                key: Key('PaymentMethodDialog'),
                insetPadding: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                      height: 500,
                      width: 350,
                      child: _editPaymentMethod(context)),
                  Positioned(top: 5, right: 5, child: DialogCloseButton())
                ]))));
  }

  Widget _editPaymentMethod(BuildContext context) {
    return Center(
        child: Container(
            width: 300,
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    key: Key('listView'),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 30),
                        Center(
                            child: Text("PaymentMethod",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold))),
                        SizedBox(height: 20),
                        Visibility(
                          visible: paymentMethod?.ccDescription != null,
                          child: Text("${paymentMethod?.ccDescription}",
                              key: Key('regCard')),
                        ),
                        SizedBox(height: 20),
                        Text("New Card:",
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        DropdownButtonFormField<String>(
                          key: Key('cardTypeDropDown'),
                          decoration: InputDecoration(labelText: 'Card Type'),
                          hint: Text('Card Type'),
                          value: _cardType.toString(),
                          validator: (value) =>
                              value == null ? 'field required' : null,
                          items: _cardType
                              .toList()
                              .map((label) => DropdownMenuItem<String>(
                                    child: Text(label),
                                    value: label,
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _cardType = CreditCardType.tryParse(newValue!);
                            });
                          },
                          isExpanded: true,
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          key: Key('creditCardNumber'),
                          decoration: InputDecoration(labelText: 'Card Number'),
                          controller: _creditCardNumberController,
                          validator: (value) {
                            var valid = _ccValidator.validateCCNum(value!);
                            if (value.isEmpty || valid == false)
                              return 'Please enter a Credit Card Number?';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          key: Key('expireMonth'),
                          decoration:
                              InputDecoration(labelText: 'Expire Month'),
                          controller: _expireMonthController,
                          validator: (value) {
                            if (value!.isEmpty)
                              return 'Please enter expiration month?';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          key: Key('expireYear'),
                          decoration: InputDecoration(labelText: 'Expire Year'),
                          controller: _expireYearController,
                          validator: (value) {
                            if (value!.isEmpty)
                              return 'Please enter a expiration year?';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Row(children: [
                          Expanded(
                              child: ElevatedButton(
                                  key: Key('updatePaymentMethod'),
                                  child: Text(
                                      paymentMethod?.creditCardNumber != null
                                          ? 'Update'
                                          : 'Add'),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      Navigator.of(context).pop(PaymentMethod(
                                        ccDescription: _cardType.toString(),
                                        creditCardType: _cardType,
                                        creditCardNumber:
                                            _creditCardNumberController.text,
                                        expireMonth:
                                            _expireMonthController.text,
                                        expireYear: _expireYearController.text,
                                      ));
                                    }
                                  }))
                        ]),
                      ],
                    )))));
  }
}
