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
  CompanyUser? _selectedCompanyUser;
  RequestType? _selectedRequestType;
  late DataFetchBloc<CompaniesUsers> _companyUserBloc;
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
    _selectedCompanyUser = (CompanyUser.tryParse(finDocUpdated.otherCompany) ??
        CompanyUser.tryParse(finDocUpdated.otherUser));
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _descriptionController.text = finDocUpdated.description ?? '';
    _pseudoIdController.text =
        finDoc.pseudoId == null ? '' : finDoc.pseudoId.toString();
    _selectedRequestType = finDocUpdated.requestType;
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(GetDataEvent<CompaniesUsers>(
          () => Future<CompaniesUsers>.value(CompaniesUsers())));
    _finDocBloc = context.read<FinDocBloc>();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key: const Key("RequestDialog"),
            child: SingleChildScrollView(
                key: const Key('listView2'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: popUp(
                    context: context,
                    height: 600,
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
    const companyLabel = "Select Requester";
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
                      child: DropdownButtonFormField<FinDocStatusVal>(
                        key: const Key('statusDropDown'),
                        decoration:
                            const InputDecoration(labelText: 'Status11'),
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
                      )),
                ],
              ),
              widget.finDoc.id() == null
                  ? const SizedBox(height: 20)
                  : RelatedFinDocs(finDoc: widget.finDoc, context: context),
              BlocBuilder<DataFetchBloc<CompaniesUsers>, DataFetchState>(
                  builder: (context, state) {
                switch (state.status) {
                  case DataFetchStatus.success:
                    return DropdownSearch<CompanyUser>(
                      enabled: !readOnly,
                      selectedItem: _selectedCompanyUser,
                      popupProps: PopupProps.menu(
                        isFilterOnline: true,
                        showSelectedItems: true,
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                            autofocus: true,
                            decoration:
                                InputDecoration(labelText: companyLabel)),
                        menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(20.0)),
                        title: popUp(
                          context: context,
                          title: companyLabel,
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: companyLabel)),
                      key: const Key('otherCompanyUser'),
                      itemAsString: (CompanyUser? u) =>
                          " ${u!.name}[${u.pseudoId}]",
                      asyncItems: (String filter) async {
                        _companyUserBloc.add(GetDataEvent(() => context
                            .read<RestClient>()
                            .getCompanyUser(
                                searchString: filter,
                                limit: 4,
                                isForDropDown: true,
                                role: Role.unknown)));
                        return Future.delayed(const Duration(milliseconds: 150),
                            () {
                          return Future.value(
                              (_companyUserBloc.state.data as CompaniesUsers)
                                  .companiesUsers);
                        });
                      },
                      compareFn: (item, sItem) => item.partyId == sItem.partyId,
                      onChanged: (CompanyUser? newValue) {
                        setState(() {
                          _selectedCompanyUser = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? "Select requester" : null,
                    );
                  case DataFetchStatus.failure:
                    return const FatalErrorForm(
                        message: 'server connection problem');
                  default:
                    return const Center(child: LoadingIndicator());
                }
              }),
              SizedBox(height: 10),
              IgnorePointer(
                ignoring: readOnly,
                child: DropdownButtonFormField<RequestType>(
                  decoration: const InputDecoration(labelText: 'Request Type'),
                  key: const Key('requestType'),
                  value: _selectedRequestType,
                  items: RequestType.values.map((item) {
                    return DropdownMenuItem<RequestType>(
                        value: item,
                        child: Text(item.name,
                            overflow: TextOverflow.ellipsis, maxLines: 2));
                  }).toList(),
                  onChanged: (newValue) => _selectedRequestType = newValue,
                  isExpanded: true,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                key: const Key('description'),
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Description'),
                controller: _descriptionController,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                      key: const Key('cancelFinDoc'),
                      child: const Text('Cancel Request'),
                      onPressed: () {
                        _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
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
                          if (requestDialogFormKey.currentState!.validate()) {
                            _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                              requestId: widget.finDoc.requestId,
                              requestType: _selectedRequestType,
                              otherCompany: _selectedCompanyUser!.getCompany(),
                              otherUser: _selectedCompanyUser!.getUser(),
                              pseudoId: _pseudoIdController.text,
                              description: _descriptionController.text,
                              status: _updatedStatus,
                              items: [],
                            )));
                          }
                        }),
                  ),
                ],
              )
            ])));
  }
}
