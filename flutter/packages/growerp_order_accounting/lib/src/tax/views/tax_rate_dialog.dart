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
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../blocs/tax_rate_bloc.dart';

/// Add or change a tax rate. Without a category it is the default rate.
class TaxRateDialog extends StatefulWidget {
  const TaxRateDialog(this.taxRate, {super.key});
  final TaxRate? taxRate;

  @override
  TaxRateDialogState createState() => TaxRateDialogState();
}

class TaxRateDialogState extends State<TaxRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentageController = TextEditingController();
  late bool _taxShipping;
  String? _categoryId;
  List<Category> _categories = [];
  late bool isNew;

  @override
  void initState() {
    super.initState();
    isNew = widget.taxRate == null;
    _nameController.text = widget.taxRate?.taxName ?? '';
    _percentageController.text =
        widget.taxRate?.taxPercentage?.toString() ?? '';
    _taxShipping = widget.taxRate?.taxShipping ?? false;
    _categoryId = widget.taxRate?.productCategoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await context.read<TaxRateBloc>().restClient.getCategory(
      limit: 100,
    );
    if (mounted) setState(() => _categories = result.categories);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    return Dialog(
      key: const Key('TaxRateDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<TaxRateBloc, TaxRateState>(
        listener: (context, state) {
          if (state.status == TaxRateStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == TaxRateStatus.success && state.message != null) {
            Navigator.of(context).pop();
          }
        },
        child: popUp(
          context: context,
          title: isNew ? localizations.newTaxRate : localizations.taxRate,
          height: 480,
          width: 400,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const Key('listView'),
              children: [
                TextFormField(
                  key: const Key('name'),
                  decoration: InputDecoration(
                    labelText: localizations.taxRateName,
                  ),
                  controller: _nameController,
                  validator: (value) => value == null || value.isEmpty
                      ? localizations.taxRateName
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('percentage'),
                  decoration: InputDecoration(
                    labelText: localizations.taxRatePercentage,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  controller: _percentageController,
                  validator: (value) => Decimal.tryParse(value ?? '') == null
                      ? localizations.taxRatePercentage
                      : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String?>(
                  key: const Key('category'),
                  initialValue:
                      _categories.any((c) => c.categoryId == _categoryId)
                      ? _categoryId
                      : null,
                  decoration: InputDecoration(
                    labelText: localizations.taxRateCategory,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(localizations.taxRateDefault),
                    ),
                    ..._categories.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.categoryId,
                        child: Text(c.categoryName),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  key: const Key('taxShipping'),
                  title: Text(localizations.taxRateShipping),
                  value: _taxShipping,
                  onChanged: (value) => setState(() => _taxShipping = value),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (!isNew) ...[
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('delete'),
                          child: Text(localizations.delete),
                          onPressed: () => context.read<TaxRateBloc>().add(
                            TaxRateDelete(widget.taxRate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('update'),
                        child: Text(
                          isNew ? localizations.addNew : localizations.update,
                        ),
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          context.read<TaxRateBloc>().add(
                            TaxRateUpdate(
                              (widget.taxRate ?? TaxRate()).copyWith(
                                taxName: _nameController.text,
                                taxPercentage: Decimal.parse(
                                  _percentageController.text,
                                ),
                                productCategoryId: _categoryId,
                                taxShipping: _taxShipping,
                              ),
                            ),
                          );
                        },
                      ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }
}
