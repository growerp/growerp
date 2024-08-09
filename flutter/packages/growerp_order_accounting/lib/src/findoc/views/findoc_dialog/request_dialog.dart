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

import 'package:growerp_core/growerp_core.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../accounting/accounting.dart';
import '../../findoc.dart';

class ShowRequestDialog extends StatelessWidget {
  final FinDoc finDoc;
  const ShowRequestDialog(this.finDoc, {super.key});
  @override
  Widget build(BuildContext context) {
    context
        .read<FinDocBloc>()
        .add(FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!));
    return BlocBuilder<FinDocBloc, FinDocState>(builder: (context, state) {
      if (state.status == FinDocStatus.success) {
        return RequestDialog(finDoc: state.finDocs[0]);
      } else {
        return const LoadingIndicator();
      }
    });
  }
}

class RequestDialog extends StatefulWidget {
  final FinDoc finDoc;
  const RequestDialog({required this.finDoc, super.key});
  @override
  RequestDialogState createState() => RequestDialogState();
}

class RequestDialogState extends State<RequestDialog> {
  final GlobalKey<FormState> requestDialogFormKey = GlobalKey<FormState>();
  late FinDoc finDoc; // incoming finDoc
  late FinDoc finDocUpdated;
  late FinDocBloc _finDocBloc;
  GlAccount? _selectedGlAccount;
  Company? _selectedCompany;
  RequestType? _selectedRequestType;
  late DataFetchBloc<Companies> _companyBloc;
  // ignore: unused_field
  late GlAccountBloc _accountBloc; // needed for accountlist
  late FinDocStatusVal _updatedStatus;

  late bool isPhone;
  late bool readOnly;
  final _pseudoIdController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    readOnly = finDoc.status == null
        ? false
        : FinDocStatusVal.statusFixed(finDoc.status!);
    _selectedCompany = finDocUpdated.otherCompany;
    _selectedGlAccount = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].glAccount
        : null;
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _selectedCompany = finDocUpdated.otherCompany;
    _pseudoIdController.text =
        finDoc.pseudoId == null ? '' : finDoc.pseudoId.toString();
    _selectedRequestType = finDocUpdated.requestType;
    _companyBloc = context.read<DataFetchBloc<Companies>>()
      ..add(
          GetDataEvent<Companies>(() => Future<Companies>.value(Companies())));
    _finDocBloc = context.read<FinDocBloc>();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key: Key("RequestDialog${finDoc.sales ? 'Sales' : 'Purchase'}"),
            child: SingleChildScrollView(
                key: const Key('listView2'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: popUp(
                    context: context,
                    height: 700,
                    width: 600,
                    title: "${finDoc.sales ? 'Incoming' : 'Outgoing'} "
                        "Request #${finDoc.pseudoId ?? 'New'}",
                    child: BlocConsumer<FinDocBloc, FinDocState>(
                      listenWhen: (previous, current) =>
                          previous.status == FinDocStatus.loading,
                      listener: (context, state) {
                        if (state.status == FinDocStatus.success) {
                          Navigator.of(context).pop();
                        }
                        if (state.status == FinDocStatus.failure) {
                          HelperFunctions.showMessage(
                              context, '${state.message}', Colors.red);
                        }
                      },
                      builder: (context, state) {
                        return requestForm(state, requestDialogFormKey);
                      },
                    )))));
  }

  Widget requestForm(
      FinDocState state, GlobalKey<FormState> requestDialogFormKey) {
    final companyLabel =
        "Select ${finDocUpdated.sales ? 'customer' : 'supplier'}";
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Form(
            key: requestDialogFormKey,
            child: Column(children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('pseudoId'),
                      enabled: !readOnly,
                      decoration: const InputDecoration(labelText: 'Id'),
                      controller: _pseudoIdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                      flex: 2,
                      child:
                          BlocBuilder<DataFetchBloc<Companies>, DataFetchState>(
                              builder: (context, state) {
                        switch (state.status) {
                          case DataFetchStatus.success:
                            return DropdownSearch<Company>(
                              enabled: !readOnly,
                              selectedItem: _selectedCompany,
                              popupProps: PopupProps.menu(
                                isFilterOnline: true,
                                showSelectedItems: true,
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                        labelText: companyLabel)),
                                menuProps: MenuProps(
                                    borderRadius: BorderRadius.circular(20.0)),
                                title: popUp(
                                  context: context,
                                  title: companyLabel,
                                  height: 50,
                                ),
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration:
                                      InputDecoration(labelText: companyLabel)),
                              key: const Key('otherCompany'),
                              itemAsString: (Company? u) => " ${u!.name}",
                              asyncItems: (String filter) async {
                                _companyBloc.add(GetDataEvent(() => context
                                    .read<RestClient>()
                                    .getCompany(
                                        searchString: filter,
                                        limit: 3,
                                        isForDropDown: true,
                                        role: widget.finDoc.sales
                                            ? Role.customer
                                            : Role.supplier)));
                                return Future.delayed(
                                    const Duration(milliseconds: 150), () {
                                  return Future.value(
                                      (_companyBloc.state.data as Companies)
                                          .companies);
                                });
                              },
                              compareFn: (item, sItem) =>
                                  item.partyId == sItem.partyId,
                              onChanged: (Company? newValue) {
                                setState(() {
                                  _selectedCompany = newValue;
                                });
                              },
                              validator: (value) => value == null
                                  ? "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}!"
                                  : null,
                            );
                          case DataFetchStatus.failure:
                            return const FatalErrorForm(
                                message: 'server connection problem');
                          default:
                            return const Center(child: LoadingIndicator());
                        }
                      })),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<FinDocStatusVal>(
                      key: const Key('statusDropDown'),
                      decoration: const InputDecoration(labelText: 'Status'),
                      value: _updatedStatus,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: FinDocStatusVal.validStatusList(
                              finDoc.status ?? FinDocStatusVal.created)
                          .map((label) => DropdownMenuItem<FinDocStatusVal>(
                                value: label,
                                child: Text(label.name),
                              ))
                          .toList(),
                      onChanged: readOnly
                          ? null
                          : (FinDocStatusVal? newValue) {
                              _updatedStatus = newValue!;
                            },
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              widget.finDoc.id() == null
                  ? const SizedBox(height: 20)
                  : RelatedFinDocs(finDoc: widget.finDoc, context: context),
              InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Request Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Column(children: [
                    IgnorePointer(
                      ignoring: readOnly,
                      child: DropdownButtonFormField<RequestType>(
                        key: const Key('requestType'),
                        value: _selectedRequestType,
                        validator: (value) =>
                            value == null && _selectedGlAccount == null
                                ? 'Enter a item type for posting?'
                                : null,
                        items: RequestType.values.map((item) {
                          return DropdownMenuItem<RequestType>(
                              value: item,
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2));
                        }).toList(),
                        onChanged: (newValue) =>
                            _selectedRequestType = newValue,
                        isExpanded: true,
                      ),
                    ),
                    TextFormField(
                      key: const Key('description'),
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      controller: _descriptionController,
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                            key: const Key('cancelFinDoc'),
                            child: const Text('Cancel Request'),
                            onPressed: () {
                              _finDocBloc
                                  .add(FinDocUpdate(finDocUpdated.copyWith(
                                status: FinDocStatusVal.cancelled,
                              )));
                            }),
                        const SizedBox(width: 20),
                        Expanded(
                          child: OutlinedButton(
                              key: const Key('update'),
                              child: Text(
                                  '${finDoc.idIsNull() ? 'Create ' : 'Update '}${finDocUpdated.docType}'),
                              onPressed: () {
                                if (requestDialogFormKey.currentState!
                                    .validate()) {
                                  _finDocBloc
                                      .add(FinDocUpdate(finDocUpdated.copyWith(
                                    otherCompany: _selectedCompany,
                                    pseudoId: _pseudoIdController.text,
                                    description: _descriptionController.text,
                                    status: _updatedStatus,
                                    requestType: _selectedRequestType,
                                    items: [],
                                  )));
                                }
                              }),
                        ),
                      ],
                    ),
                  ]))
            ])));
  }
}
