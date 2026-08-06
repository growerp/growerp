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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:credit_card_validator/credit_card_validator.dart';
import 'package:global_configuration/global_configuration.dart';
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
    // Check if we should use test data
    bool isTestMode = !kReleaseMode || GlobalConfiguration().get("test");

    _cardType =
        (widget.paymentMethod?.creditCardType ??
        CreditCardType.getByValue(''))!;

    // If no existing payment method and in test mode, use test data
    if (widget.paymentMethod?.creditCardNumber == null && isTestMode) {
      _creditCardNumberController.text = '4242424242424242';
      _expireMonthController.text = '11';
      _expireYearController.text = '33';
      _cardType = CreditCardType.visa;
    } else {
      _creditCardNumberController.text =
          widget.paymentMethod?.creditCardNumber ?? '';
      _expireMonthController.text = widget.paymentMethod?.expireMonth ?? '';
      _expireYearController.text = widget.paymentMethod?.expireYear ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = UserCompanyLocalizations.of(context)!;
    return Dialog(
      key: const Key('PaymentMethodDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        height: 450,
        width: 350,
        title: localizations.paymentMethodDetail,
        child: _editPaymentMethod(localizations),
      ),
    );
  }

  Widget _editPaymentMethod(UserCompanyLocalizations localizations) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const Key('paymentMethodListView'),
        child: Column(
          children: <Widget>[
            Visibility(
              visible: widget.paymentMethod?.ccDescription != null,
              child: Text(
                "${widget.paymentMethod?.ccDescription}",
                key: const Key('regCard'),
              ),
            ),
            Text(
              localizations.paymentMethodNewCard,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<CreditCardType>(
              key: const Key('cardTypeDropDown'),
              decoration: InputDecoration(
                labelText: localizations.paymentMethodCardType,
              ),
              hint: Text(localizations.paymentMethodCardType),
              initialValue: _cardType,
              validator: (value) =>
                  value == null ? localizations.fieldRequired : null,
              items: CreditCardType.values
                  .map(
                    (item) => DropdownMenuItem<CreditCardType>(
                      value: item,
                      child: Text(item.value),
                    ),
                  )
                  .toList(),
              onChanged: (CreditCardType? newValue) {
                setState(() {
                  _cardType = newValue!;
                });
              },
              isExpanded: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('creditCardNumber'),
              decoration: InputDecoration(
                labelText: localizations.paymentMethodCardNumber,
              ),
              controller: _creditCardNumberController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.paymentMethodCardNumberError;
                }
                var valid = _ccValidator.validateCCNum(value);
                if (!valid.isPotentiallyValid) {
                  return localizations.paymentMethodCardNumberInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('expireMonth'),
                    decoration: InputDecoration(
                      labelText: localizations.paymentMethodExpireMonth,
                    ),
                    controller: _expireMonthController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return localizations.paymentMethodExpireMonthError;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('expireYear'),
                    decoration: InputDecoration(
                      labelText: localizations.paymentMethodExpireYear,
                    ),
                    controller: _expireYearController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return localizations.paymentMethodExpireYearError;
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
                  child: OutlinedButton(
                    key: const Key('updatePaymentMethod'),
                    child: Text(
                      widget.paymentMethod?.creditCardNumber != null
                          ? localizations.update
                          : localizations.add,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final cardNumber = _creditCardNumberController.text;
                        final maskedNumber =
                            '${'*' * (cardNumber.length - 4)}${cardNumber.substring(cardNumber.length - 4)}';
                        final description =
                            '$_cardType$maskedNumber ${_expireMonthController.text}/${_expireYearController.text}';
                        Navigator.of(context).pop(
                          PaymentMethod(
                            ccDescription: description,
                            creditCardType: _cardType,
                            creditCardNumber: cardNumber,
                            expireMonth: _expireMonthController.text,
                            expireYear: _expireYearController.text,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
