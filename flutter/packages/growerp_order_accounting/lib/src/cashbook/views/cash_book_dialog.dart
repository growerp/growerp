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
import 'package:intl/intl.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../blocs/cash_book_bloc.dart';

/// Add or change one cash book entry: direction, date, amount, category,
/// description and an optional customer/supplier.
class CashBookDialog extends StatefulWidget {
  final CashBookEntry entry;
  const CashBookDialog(this.entry, {super.key});
  @override
  CashBookDialogState createState() => CashBookDialogState();
}

class CashBookDialogState extends State<CashBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late CashBookBloc _cashBookBloc;
  late DataFetchBloc<CompaniesUsers> _companyUserBloc;
  late OrderAccountingLocalizations _localizations;
  late bool isIncome;
  late DateTime date;
  String? categoryId;
  CompanyUser? _selectedParty;
  late bool readOnly;
  late bool isNew;

  @override
  void initState() {
    super.initState();
    _cashBookBloc = context.read<CashBookBloc>();
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>();
    final entry = widget.entry;
    isNew = entry.transactionId == null;
    readOnly = entry.source != 'manual';
    isIncome = entry.isIncome;
    date = entry.date ?? DateTime.now();
    categoryId = entry.category?.glAccountId;
    _amountController.text = entry.amount == null
        ? ''
        : entry.amount.currency(currencyId: '');
    _descriptionController.text = entry.description;
    _selectedParty = CompanyUser.tryParse(
      entry.otherCompany ?? entry.otherUser,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    bool isPhone = isAPhone(context);
    return BlocListener<CashBookBloc, CashBookState>(
      listener: (context, state) {
        // only a saved/deleted entry closes the dialog, not the category load
        if (state.status == CashBookStatus.success && state.message != null) {
          Navigator.of(context).pop();
        }
        if (state.status == CashBookStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      child: Dialog(
        key: const Key('CashBookDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: isNew
              ? _localizations.newCashBookEntry
              : '${_localizations.cashBookEntry} ${widget.entry.pseudoId ?? ''}',
          width: isPhone ? 400 : 600,
          height: isPhone ? 650 : 560,
          child: _form(),
        ),
      ),
    );
  }

  Widget _form() {
    return BlocBuilder<CashBookBloc, CashBookState>(
      buildWhen: (previous, current) =>
          previous.incomeCategories != current.incomeCategories ||
          previous.expenseCategories != current.expenseCategories,
      builder: (context, state) {
        final categories = isIncome
            ? state.incomeCategories
            : state.expenseCategories;
        // keep the selection only when it belongs to the current direction
        if (categoryId != null &&
            !categories.any((c) => c.glAccountId == categoryId)) {
          categoryId = null;
        }
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            key: const Key('listView'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (readOnly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _localizations.cashReadOnly,
                      key: const Key('readOnlyNotice'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                SegmentedButton<bool>(
                  key: const Key('isIncome'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.arrow_downward),
                      label: Text(
                        _localizations.cashIn,
                        key: const Key('dirIn'),
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.arrow_upward),
                      label: Text(
                        _localizations.cashOut,
                        key: const Key('dirOut'),
                      ),
                    ),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: readOnly
                      ? null
                      : (selection) =>
                            setState(() => isIncome = selection.first),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  key: const Key('date'),
                  readOnly: true,
                  enabled: !readOnly,
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd').format(date),
                  ),
                  decoration: InputDecoration(
                    labelText: _localizations.date,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: readOnly
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(date.year - 10),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) setState(() => date = picked);
                        },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  key: const Key('amount'),
                  enabled: !readOnly,
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: _localizations.amount),
                  validator: (value) {
                    final amount = Decimal.tryParse(value ?? '');
                    return amount == null || amount <= Decimal.zero
                        ? _localizations.cashAmountInvalid
                        : null;
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  key: const Key('category'),
                  isExpanded: true,
                  initialValue: categoryId,
                  decoration: InputDecoration(
                    labelText: _localizations.cashCategory,
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        key: Key('category${category.glAccountId}'),
                        value: category.glAccountId,
                        // the account code behind a category means nothing to
                        // the user of the cash book, only the name is shown
                        child: Text(
                          category.accountName ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: readOnly
                      ? null
                      : (value) => setState(() => categoryId = value),
                  validator: (value) => value == null
                      ? _localizations.cashCategoryRequired
                      : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  key: const Key('description'),
                  enabled: !readOnly,
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: _localizations.description,
                  ),
                ),
                const SizedBox(height: 15),
                AutocompleteLabel<CompanyUser>(
                  key: const Key('otherParty'),
                  label: _localizations.cashParty,
                  initialValue: _selectedParty,
                  readOnly: readOnly,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    _companyUserBloc.add(
                      GetDataEvent(
                        () => context.read<RestClient>().getCompanyUser(
                          searchString: textEditingValue.text,
                          limit: 5,
                        ),
                      ),
                    );
                    return Future.delayed(
                      const Duration(milliseconds: 150),
                      () =>
                          (_companyUserBloc.state.data as CompaniesUsers?)
                              ?.companiesUsers ??
                          <CompanyUser>[],
                    );
                  },
                  displayStringForOption: (CompanyUser u) => u.name ?? '',
                  onSelected: (CompanyUser? value) =>
                      setState(() => _selectedParty = value),
                ),
                const SizedBox(height: 20),
                if (!readOnly)
                  Row(
                    children: [
                      if (!isNew)
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('delete'),
                            onPressed: () async {
                              final confirmed = await confirmDialog(
                                context,
                                _localizations.cashDeleteConfirm,
                                '',
                              );
                              if (confirmed == true) {
                                _cashBookBloc.add(CashBookDelete(widget.entry));
                              }
                            },
                            child: Text(_localizations.delete),
                          ),
                        ),
                      if (!isNew) const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('update'),
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            _cashBookBloc.add(
                              CashBookUpdate(
                                widget.entry.copyWith(
                                  isIncome: isIncome,
                                  date: date,
                                  amount: Decimal.parse(_amountController.text),
                                  category: GlAccount(glAccountId: categoryId),
                                  description: _descriptionController.text,
                                  otherCompany: _selectedParty?.getCompany(),
                                  otherUser: _selectedParty?.getUser(),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isNew
                                ? _localizations.create
                                : _localizations.update,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
