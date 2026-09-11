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
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../blocs/cash_book_category_bloc.dart';

/// Add a category of your own or rename an existing one. Income or expense can
/// only be chosen when adding: it is fixed by the ledger account behind it.
class CashBookCategoryDialog extends StatefulWidget {
  const CashBookCategoryDialog(
    this.category, {
    super.key,
    this.isIncome = true,
  });
  final GlAccount? category;
  final bool isIncome;

  @override
  CashBookCategoryDialogState createState() => CashBookCategoryDialogState();
}

class CashBookCategoryDialogState extends State<CashBookCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late bool _isIncome;
  late bool _isUsed;
  late bool isNew;

  @override
  void initState() {
    super.initState();
    isNew = widget.category == null;
    _nameController.text = widget.category?.accountName ?? '';
    _isIncome = isNew ? widget.isIncome : !(widget.category!.isDebit ?? true);
    _isUsed = widget.category?.isUsed ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    return Dialog(
      key: const Key('CashBookCategoryDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<CashBookCategoryBloc, CashBookCategoryState>(
        listener: (context, state) {
          if (state.status == CashBookCategoryStatus.failure) {
            HelperFunctions.showMessage(context, state.message, Colors.red);
          }
          if (state.status == CashBookCategoryStatus.success &&
              state.message != null) {
            Navigator.of(context).pop();
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newCashBookCategory
              : localizations.cashBookCategory,
          height: 400,
          width: 400,
          child: Form(
            key: _formKey,
            child: ListView(
              key: const Key('listView'),
              children: [
                TextFormField(
                  key: const Key('name'),
                  decoration: InputDecoration(
                    labelText: localizations.cashBookCategoryName,
                  ),
                  controller: _nameController,
                  validator: (value) => value == null || value.isEmpty
                      ? localizations.cashBookCategoryName
                      : null,
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  key: const Key('directionSelect'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(
                        localizations.cashIn,
                        key: const Key('dirIn'),
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(
                        localizations.cashOut,
                        key: const Key('dirOut'),
                      ),
                    ),
                  ],
                  selected: {_isIncome},
                  // the direction follows the ledger account, so it is fixed
                  onSelectionChanged: isNew
                      ? (selection) =>
                            setState(() => _isIncome = selection.first)
                      : null,
                ),
                if (!isNew) ...[
                  const SizedBox(height: 20),
                  SwitchListTile(
                    key: const Key('inUse'),
                    title: Text(localizations.cashBookCategoryInUse),
                    subtitle: Text(localizations.cashBookCategoryHelp),
                    value: _isUsed,
                    onChanged: (value) => setState(() => _isUsed = value),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('update'),
                  child: Text(
                    isNew ? localizations.addNew : localizations.update,
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final bloc = context.read<CashBookCategoryBloc>();
                    if (isNew) {
                      bloc.add(
                        CashBookCategoryCreate(
                          accountName: _nameController.text,
                          isIncome: _isIncome,
                        ),
                      );
                    } else {
                      bloc.add(
                        CashBookCategoryUpdate(
                          widget.category!,
                          isUsed: _isUsed,
                          accountName: _nameController.text,
                        ),
                      );
                    }
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
    _nameController.dispose();
    super.dispose();
  }
}
