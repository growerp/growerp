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

import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  late String classificationId;
  late AuthBloc _authBloc;

  late bool isPhone;
  late bool readOnly;
  final _pseudoIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _postalController = TextEditingController();
  final _telephoneController = TextEditingController();
  late User user;
  String? selectedCare;
  String? selectedForWhom;
  String? selectedTimeframe;
  String? selectedHowSoon;
  String? selectedStatus;

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
    classificationId = context.read<String>();
    _authBloc = context.read<AuthBloc>();
    user = _authBloc.state.authenticate?.user as User;
    if (finDoc.description != null) {
      try {
        Map jsonDescription =
            finDoc.description != null ? jsonDecode(finDoc.description!) : {};
        _telephoneController.text = jsonDescription['Telephone Number'] ?? '';
        _postalController.text = jsonDescription['CarePostCode'] ?? '';
        selectedCare = jsonDescription['TypeOfCare'] ?? '';
        selectedForWhom = jsonDescription['CareRelationship'] ?? '';
        selectedTimeframe = jsonDescription['CareTimeframe'] ?? '';
        selectedHowSoon = jsonDescription['HowSoonCare'] ?? '';
        selectedStatus = jsonDescription['ACAT_Status'] ?? '';
      } on FormatException catch (_) {
        _descriptionController.text = finDoc.description ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            insetPadding: const EdgeInsets.all(10), // need for width
            key: const Key("RequestDialog"),
            child: SingleChildScrollView(
                key: const Key('listView2'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: popUp(
                    context: context,
                    height: 650,
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
                        return classificationId == 'AppHealth'
                            ? healthRequestForm(
                                state, requestDialogFormKey, isPhone, user)
                            : requestForm(state, requestDialogFormKey);
                      },
                    )))));
  }

  Widget healthRequestForm(FinDocState state,
      GlobalKey<FormState> requestDialogFormKey, bool isPhone, User user) {
    var companyLabel = 'Company';
    if (kDebugMode && widget.finDoc.requestId == null) {
      _telephoneController.text = '99999999';
      _postalController.text = '5555555';
      selectedCare = 'resCare';
      selectedForWhom = 'mySelf';
      selectedTimeframe = 'unSure';
      selectedHowSoon = 'asap';
      selectedStatus = 'unSure';
    }
    return Padding(
        padding: EdgeInsets.fromLTRB(isPhone ? 8 : 80, 0, isPhone ? 8 : 80, 0),
        child: Form(
            key: requestDialogFormKey,
            child: Column(children: <Widget>[
              const SizedBox(height: 10),
              Text("Enter your request for ${user.firstName} ${user.lastName}"),
              const SizedBox(height: 10),
              if (finDoc.requestId != null &&
                  finDoc.otherUser?.partyId != user.partyId)
                BlocBuilder<DataFetchBloc<CompaniesUsers>, DataFetchState>(
                    builder: (context, state) {
                  switch (state.status) {
                    case DataFetchStatus.success:
                      return DropdownSearch<CompanyUser>(
                        enabled: !readOnly,
                        key: const Key('otherCompanyUser'),
                        selectedItem: _selectedCompanyUser,
                        popupProps: PopupProps.menu(
                          isFilterOnline: true,
                          showSelectedItems: true,
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
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
                        dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration:
                                InputDecoration(labelText: companyLabel)),
                        itemAsString: (CompanyUser? u) =>
                            " ${u!.name}[${u.pseudoId}]",
                        asyncItems: (String filter) async {
                          _companyUserBloc.add(GetDataEvent(() => context
                              .read<RestClient>()
                              .getCompanyUser(
                                  searchString: filter,
                                  limit: 4,
                                  role: Role.unknown)));
                          return Future.delayed(
                              const Duration(milliseconds: 150), () {
                            return Future.value(
                                (_companyUserBloc.state.data as CompaniesUsers)
                                    .companiesUsers);
                          });
                        },
                        compareFn: (item, sItem) =>
                            item.partyId == sItem.partyId,
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
              const SizedBox(height: 10),
              if (finDoc.requestId != null)
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
                              const InputDecoration(labelText: 'Status'),
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
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('postalCode'),
                enabled: !readOnly,
                decoration: const InputDecoration(
                    labelText: 'In which Post Code are you looking for care?'),
                controller: _postalController,
                //keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('telephone'),
                enabled: !readOnly,
                decoration: const InputDecoration(
                    labelText: 'What is your telephone number?'),
                controller: _telephoneController,
                //keyboardType: _telephoneController.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('care'),
                      value: selectedCare,
                      decoration: const InputDecoration(
                          labelText: 'What type of care are you looking for?'),
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: const [
                        DropdownMenuItem<String>(
                            value: 'resCare', child: Text('Residential Care')),
                        DropdownMenuItem<String>(
                            value: 'homeCare', child: Text('Home Care')),
                        DropdownMenuItem<String>(
                            value: 'stCare', child: Text('Short term Care')),
                        DropdownMenuItem<String>(
                            value: 'retLiving',
                            child: Text('Retirement Living')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (String? newValue) {
                        selectedCare = newValue!;
                      },
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('forWhom'),
                      value: selectedForWhom,
                      decoration: const InputDecoration(
                          labelText: 'Who is the care for?'),
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: const [
                        DropdownMenuItem<String>(
                            value: 'mySelf', child: Text('Myself')),
                        DropdownMenuItem<String>(
                            value: 'myParent', child: Text('My parent')),
                        DropdownMenuItem<String>(
                            value: 'myPartner', child: Text('My partner')),
                        DropdownMenuItem<String>(
                            value: 'myChild', child: Text('My child')),
                        DropdownMenuItem<String>(
                            value: 'myClient', child: Text('My client')),
                        DropdownMenuItem<String>(
                            value: 'Other', child: Text('Other')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (String? newValue) {
                        selectedForWhom = newValue!;
                      },
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('timeframe'),
                      value: selectedTimeframe,
                      decoration: const InputDecoration(
                          labelText:
                              'What sort of timeframe are you looking for?'),
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: const [
                        DropdownMenuItem<String>(
                            value: 'unSure', child: Text('I am not sure')),
                        DropdownMenuItem<String>(
                            value: 'shortTerm', child: Text('Short-term')),
                        DropdownMenuItem<String>(
                            value: 'longTerm', child: Text('Long-term')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (String? newValue) {
                        selectedTimeframe = newValue!;
                      },
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('howSoon'),
                      value: selectedHowSoon,
                      decoration: const InputDecoration(
                          labelText: 'How soon may you require care?'),
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: const [
                        DropdownMenuItem<String>(
                            value: 'asap', child: Text('As soon as possible')),
                        DropdownMenuItem<String>(
                            value: '3Months',
                            child: Text('Within three months')),
                        DropdownMenuItem<String>(
                            value: '6Months', child: Text('Within six months')),
                        DropdownMenuItem<String>(
                            value: 'moreMonths',
                            child: Text('More than 6 months')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (String? newValue) {
                        selectedHowSoon = newValue!;
                      },
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: const Key('status'),
                value: selectedStatus,
                decoration: const InputDecoration(
                    labelText: 'What is the status of your ACAT assessment?'),
                validator: (value) => value == null ? 'field required' : null,
                items: const [
                  DropdownMenuItem<String>(
                      value: 'unSure', child: Text('I am not sure')),
                  DropdownMenuItem<String>(
                      value: 'yettobestarted',
                      child: Text('Have not started the assesment')),
                  DropdownMenuItem<String>(
                      value: 'inProgress',
                      child: Text('Assesment in progress')),
                  DropdownMenuItem<String>(
                      value: 'complete', child: Text('Assesment complete')),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (String? newValue) {
                  selectedStatus = newValue!;
                },
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                  key: const Key('update'),
                  child: Text(
                      '${finDoc.idIsNull() ? 'Create ' : 'Update '}${finDocUpdated.docType}'),
                  onPressed: () {
                    var description = jsonEncode({
                      'CarePostCode': _postalController.text,
                      'Telephone Number': _telephoneController.text,
                      'TypeOfCare': selectedCare,
                      'CareRelationship': selectedForWhom,
                      'CareTimeframe': selectedTimeframe,
                      'HowSoonCare': selectedHowSoon,
                      'ACAT_Status': selectedStatus,
                    });
                    if (requestDialogFormKey.currentState!.validate()) {
                      _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                        requestId: widget.finDoc.requestId,
                        requestType: _selectedRequestType,
                        otherCompany: user.company,
                        otherUser: user,
                        pseudoId: _pseudoIdController.text,
                        description: description,
                        status: _updatedStatus,
                        items: [],
                      )));
                    }
                  }),
            ])));
  }

  Widget requestForm(
      FinDocState state, GlobalKey<FormState> requestDialogFormKey) {
    const companyLabel = "Requester";
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
                      key: const Key('otherCompanyUser'),
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
                      itemAsString: (CompanyUser? u) =>
                          " ${u!.name}[${u.pseudoId}]",
                      asyncItems: (String filter) async {
                        _companyUserBloc.add(GetDataEvent(() => context
                            .read<RestClient>()
                            .getCompanyUser(
                                searchString: filter,
                                limit: 4,
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('description'),
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Description'),
                controller: _descriptionController,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        key: const Key('cancelFinDoc'),
                        child: const Text('Cancel Request'),
                        onPressed: () {
                          _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                            status: FinDocStatusVal.cancelled,
                          )));
                        }),
                  ),
                  const SizedBox(width: 20),
                  OutlinedButton(
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
                ],
              )
            ])));
  }
}
