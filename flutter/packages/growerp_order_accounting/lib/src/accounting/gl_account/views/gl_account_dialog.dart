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

import 'package:dropdown_search/dropdown_search.dart';
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
  bool? debitSelected;
  AccountClass? classSelected;
  AccountType? typeSelected;
  late GlAccountBloc _glAccountBloc;

  @override
  void initState() {
    super.initState();
    _glAccountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountTypesFetch())
      ..add(const GlAccountClassesFetch());
    if (widget.glAccount.glAccountId != null) {
      _accountCodeController.text = widget.glAccount.accountCode ?? '';
      _accountNameController.text = widget.glAccount.accountName ?? '';
      _postedBalanceController.text = widget.glAccount.postedBalance == null
          ? '0'
          : widget.glAccount.postedBalance.toString();
      debitSelected = widget.glAccount.isDebit;
      classSelected = widget.glAccount.accountClass;
      typeSelected = widget.glAccount.accountType;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  context, 'Error: ${state.message}', Colors.red);
              break;
            default:
              const Text("????");
          }
        },
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Dialog(
                key: const Key('GlAccountDialog'),
                insetPadding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                    context: context,
                    title:
                        "GlAccount #${widget.glAccount.accountCode ?? " New"}",
                    width: columns.toDouble() * 400,
                    height: columns == 1
                        ? 1 / columns.toDouble() * 650
                        : 1 / columns.toDouble() * 700,
                    child: BlocBuilder<GlAccountBloc, GlAccountState>(
                        builder: (context, state) {
                      switch (state.status) {
                        case GlAccountStatus.failure:
                          return const FatalErrorForm(
                              message: 'server connection problem');
                        case GlAccountStatus.success:
                          return _glAccountForm(state);
                        default:
                          return const Center(
                              child: CircularProgressIndicator());
                      }
                    })))));
  }

  Widget _glAccountForm(state) {
    List<Widget> widgets = [
      TextFormField(
        key: const Key('code'),
        decoration: const InputDecoration(labelText: 'GlAccount Id'),
        controller: _accountCodeController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a glAccount Id?' : null;
        },
      ),
      TextFormField(
        key: const Key('name'),
        decoration: const InputDecoration(labelText: 'GlAccount Name'),
        controller: _accountNameController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a glAccount name?' : null;
        },
      ),
      if (widget.glAccount.glAccountId != null)
        CreditDebitButton(
            isDebit: debitSelected,
            canUpdate: false,
            onValueChanged: (debitSelected) {}),
      DropdownSearch<AccountClass>(
        key: const Key('class'),
        selectedItem: classSelected,
        popupProps: PopupProps.menu(
          isFilterOnline: true,
          showSelectedItems: true,
          showSearchBox: true,
          searchFieldProps: const TextFieldProps(
            autofocus: true,
            decoration: InputDecoration(labelText: 'Account Class'),
          ),
          menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
          title: popUp(
            context: context,
            title: 'Select GL Account Class',
            height: 50,
          ),
        ),
        dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration:
                InputDecoration(labelText: 'AccountClass')),
        itemAsString: (AccountClass? u) =>
            " ${u!.topDescription!.substring(0, 1)}-${u.parentDescription}-"
            "${u.description}-${u.detailDescription}",
        asyncItems: (String filter) async {
          _glAccountBloc
              .add(GlAccountClassesFetch(searchString: filter, limit: 3));
          return Future.delayed(const Duration(milliseconds: 100), () {
            return Future.value(_glAccountBloc.state.accountClasses);
          });
        },
        compareFn: (item, sItem) =>
            item.topClassId == sItem.topClassId &&
            item.parentClassId == sItem.parentClassId &&
            item.classId == sItem.classId &&
            item.detailClassId == sItem.detailClassId,
        onChanged: (AccountClass? newValue) {
          classSelected = newValue!;
        },
        validator: (value) => value == null ? 'field required' : null,
      ),
      DropdownSearch<AccountType>(
        key: const Key('type'),
        selectedItem: typeSelected,
        popupProps: PopupProps.menu(
          isFilterOnline: true,
          showSelectedItems: true,
          showSearchBox: true,
          searchFieldProps: const TextFieldProps(
            autofocus: true,
            decoration: InputDecoration(labelText: 'Account Type'),
          ),
          menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
          title: popUp(
            context: context,
            title: 'Select GL Account Type',
            height: 50,
          ),
        ),
        dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration:
                InputDecoration(labelText: 'Account Type')),
        itemAsString: (AccountType? u) => " ${u!.description}",
        asyncItems: (String filter) async {
          _glAccountBloc
              .add(GlAccountTypesFetch(searchString: filter, limit: 3));
          return Future.delayed(const Duration(milliseconds: 100), () {
            return Future.value(_glAccountBloc.state.accountTypes);
          });
        },
        compareFn: (item, sItem) => item.accountTypeId == sItem.accountTypeId,
        onChanged: (AccountType? newValue) {
          typeSelected = newValue!;
        },
      ),
      TextFormField(
        key: const Key('postedBalance'),
        decoration: const InputDecoration(labelText: 'Posted Balance'),
        controller: _postedBalanceController,
      ),
      ElevatedButton(
          key: const Key('update'),
          child:
              Text(widget.glAccount.glAccountId == null ? 'Create' : 'Update'),
          onPressed: () {
            if (_formKeyGlAccount.currentState!.validate()) {
              _glAccountBloc.add(GlAccountUpdate(GlAccount(
                glAccountId: widget.glAccount.glAccountId,
                accountName: _accountNameController.text,
                accountCode: _accountCodeController.text,
                accountClass: AccountClass(
                    description: classSelected!.detailDescription!.isNotEmpty
                        ? classSelected?.detailDescription
                        : classSelected!.description!.isNotEmpty
                            ? classSelected?.description
                            : classSelected!.parentDescription!.isNotEmpty
                                ? classSelected?.parentDescription
                                : classSelected?.topDescription),
                accountType: typeSelected,
              )));
            }
          }),
    ];

    List<Widget> rows = [];
    List<Widget> column = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(5), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    } else {
      for (var i = 0; i < widgets.length; i++) {
        column.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: widgets[i],
        ));
      }
    }

    return Form(
      key: _formKeyGlAccount,
      child: SingleChildScrollView(
          key: const Key('listView'),
          padding: const EdgeInsets.all(20),
          child: Column(children: rows.isEmpty ? column : rows)),
    );
  }
}
