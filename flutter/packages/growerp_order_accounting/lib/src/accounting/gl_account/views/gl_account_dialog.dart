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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_order_accounting.dart';

class GlAccountDialog extends StatefulWidget {
  final GlAccount glAccount;
  const GlAccountDialog(this.glAccount, {super.key});
  @override
  GlAccountDialogState createState() => GlAccountDialogState();
}

class GlAccountDialogState extends State<GlAccountDialog> {
  final _formKeyGlAccount = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _accountCodeController = TextEditingController();
  final _postedBalanceController = TextEditingController();
  final _classController = TextEditingController();
  final _typeController = TextEditingController();
  bool? debitSelected;
  AccountClass? classSelected;
  AccountType? typeSelected;
  late GlAccountBloc _glAccountBloc;
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _glAccountBloc = context.read<GlAccountBloc>();
    // Fetch all classes and types via BLoC
    _glAccountBloc.add(const GlAccountClassesFetch(limit: 100));
    _glAccountBloc.add(const GlAccountTypesFetch(limit: 100));
    if (widget.glAccount.glAccountId != null) {
      _accountCodeController.text = widget.glAccount.accountCode ?? '';
      _accountNameController.text = widget.glAccount.accountName ?? '';
      _postedBalanceController.text = widget.glAccount.postedBalance == null
          ? '0'
          : widget.glAccount.postedBalance.toString();
      debitSelected = widget.glAccount.isDebit;
      classSelected = widget.glAccount.accountClass;
      typeSelected = widget.glAccount.accountType;
      _classController.text = classSelected != null
          ? _classDisplayString(classSelected!)
          : '';
      _typeController.text = typeSelected?.description ?? '';
    } else {
      debitSelected = true; // default to debit for new accounts
    }
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    int columns = ResponsiveBreakpoints.of(context).isMobile ? 1 : 2;
    return BlocListener<GlAccountBloc, GlAccountState>(
      listenWhen: (previous, current) =>
          previous.status == GlAccountStatus.glAccountLoading,
      listener: (context, state) async {
        switch (state.status) {
          case GlAccountStatus.success:
            Navigator.of(context).pop();
            break;
          case GlAccountStatus.failure:
            HelperFunctions.showMessage(
              context,
              'Error: ${state.message}',
              Colors.red,
            );
            break;
          default:
            const Text("????");
        }
      },
      child: Dialog(
        key: const Key('GlAccountDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title:
              "${_localizations.glAccount}${widget.glAccount.accountCode ?? _localizations.newGlAccount}",
          width: columns.toDouble() * 400,
          height: columns == 1
              ? 1 / columns.toDouble() * 650
              : 1 / columns.toDouble() * 700,
          child: BlocBuilder<GlAccountBloc, GlAccountState>(
            builder: (context, state) {
              switch (state.status) {
                case GlAccountStatus.failure:
                  return FatalErrorForm(message: _localizations.serverProblem);
                case GlAccountStatus.success:
                  return _glAccountForm(state);
                default:
                  return const Center(child: LoadingIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  String _classDisplayString(AccountClass ac) {
    return '${ac.topDescription?.substring(0, 1) ?? ''}-'
        '${ac.parentDescription ?? ''}-'
        '${ac.description ?? ''}-'
        '${ac.detailDescription ?? ''}';
  }

  Widget _glAccountForm(GlAccountState state) {
    List<Widget> widgets = [
      TextFormField(
        key: const Key('code'),
        decoration: InputDecoration(labelText: _localizations.glAccountId),
        controller: _accountCodeController,
        validator: (value) {
          return value!.isEmpty ? _localizations.glAccountIdNull : null;
        },
      ),
      TextFormField(
        key: const Key('name'),
        decoration: InputDecoration(labelText: _localizations.glAccountName),
        controller: _accountNameController,
        validator: (value) {
          return value!.isEmpty ? _localizations.glAccountNameNull : null;
        },
      ),
      RadioGroup<bool>(
        groupValue: debitSelected,
        onChanged: (bool? value) {
          setState(() {
            debitSelected = value;
          });
        },
        child: const Row(
          children: [
            Expanded(
              child: Row(
                children: [Text('Debit account'), Radio<bool>(value: true)],
              ),
            ),
            Expanded(
              child: Row(
                children: [Text('Credit account'), Radio<bool>(value: false)],
              ),
            ),
          ],
        ),
      ),
      Autocomplete<AccountClass>(
        key: const Key('class'),
        initialValue: TextEditingValue(text: _classController.text),
        displayStringForOption: (AccountClass ac) => _classDisplayString(ac),
        optionsBuilder: (TextEditingValue textEditingValue) {
          final query = textEditingValue.text.toLowerCase();
          if (query.isEmpty) return _glAccountBloc.state.accountClasses;
          return _glAccountBloc.state.accountClasses.where((ac) {
            return _classDisplayString(ac).toLowerCase().contains(query);
          }).toList();
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              // Sync the external controller for test readability
              _classController.text = textController.text;
              textController.addListener(() {
                _classController.text = textController.text;
              });
              return TextFormField(
                key: const Key('classField'),
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: _localizations.accountClass,
                ),
                onFieldSubmitted: (_) => onFieldSubmitted(),
                validator: (value) =>
                    classSelected == null ? _localizations.fieldRequired : null,
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 250,
                  maxWidth: 400,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final ac = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(_classDisplayString(ac)),
                      onTap: () => onSelected(ac),
                    );
                  },
                ),
              ),
            ),
          );
        },
        onSelected: (AccountClass selection) {
          classSelected = selection;
          _classController.text = _classDisplayString(selection);
        },
      ),
      Autocomplete<AccountType>(
        key: const Key('type'),
        initialValue: TextEditingValue(text: _typeController.text),
        displayStringForOption: (AccountType at) => at.description ?? '',
        optionsBuilder: (TextEditingValue textEditingValue) {
          final query = textEditingValue.text.toLowerCase();
          if (query.isEmpty) return _glAccountBloc.state.accountTypes;
          return _glAccountBloc.state.accountTypes.where((at) {
            return (at.description ?? '').toLowerCase().contains(query);
          }).toList();
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              _typeController.text = textController.text;
              textController.addListener(() {
                _typeController.text = textController.text;
              });
              return TextFormField(
                key: const Key('typeField'),
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: _localizations.accountType,
                ),
                onFieldSubmitted: (_) => onFieldSubmitted(),
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 250,
                  maxWidth: 400,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final at = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(at.description ?? ''),
                      onTap: () => onSelected(at),
                    );
                  },
                ),
              ),
            ),
          );
        },
        onSelected: (AccountType selection) {
          typeSelected = selection;
          _typeController.text = selection.description ?? '';
        },
      ),
      TextFormField(
        key: const Key('postedBalance'),
        decoration: InputDecoration(labelText: _localizations.postedBalance),
        controller: _postedBalanceController,
      ),
      OutlinedButton(
        key: const Key('update'),
        child: Text(
          widget.glAccount.glAccountId == null
              ? _localizations.create
              : _localizations.update,
        ),
        onPressed: () {
          if (_formKeyGlAccount.currentState!.validate()) {
            _glAccountBloc.add(
              GlAccountUpdate(
                GlAccount(
                  glAccountId: widget.glAccount.glAccountId,
                  accountName: _accountNameController.text,
                  accountCode: _accountCodeController.text,
                  isDebit: debitSelected,
                  accountClass: AccountClass(
                    description: classSelected!.detailDescription!.isNotEmpty
                        ? classSelected?.detailDescription
                        : classSelected!.description!.isNotEmpty
                        ? classSelected?.description
                        : classSelected!.parentDescription!.isNotEmpty
                        ? classSelected?.parentDescription
                        : classSelected?.topDescription,
                  ),
                  accountType: typeSelected,
                ),
              ),
            );
          }
        },
      ),
    ];

    List<Widget> rows = [];
    List<Widget> column = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: widgets[i++],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: i < widgets.length ? widgets[i] : Container(),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      for (var i = 0; i < widgets.length; i++) {
        column.add(
          Padding(padding: const EdgeInsets.all(8.0), child: widgets[i]),
        );
      }
    }

    return Form(
      key: _formKeyGlAccount,
      child: SingleChildScrollView(
        key: const Key('listView'),
        padding: const EdgeInsets.all(20),
        child: Column(children: rows.isEmpty ? column : rows),
      ),
    );
  }
}
