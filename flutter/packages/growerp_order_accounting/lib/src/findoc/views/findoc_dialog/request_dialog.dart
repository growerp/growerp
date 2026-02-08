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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../l10n/generated/order_accounting_localizations.dart';

import '../../../accounting/accounting.dart';
import '../../findoc.dart';

class ShowRequestDialog extends StatelessWidget {
  final FinDoc finDoc;
  const ShowRequestDialog(this.finDoc, {super.key});
  @override
  Widget build(BuildContext context) {
    context.read<FinDocBloc>().add(
      FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!),
    );
    return BlocBuilder<FinDocBloc, FinDocState>(
      builder: (context, state) {
        if (state.status == FinDocStatus.success) {
          return RequestDialog(finDoc: state.finDocs[0]);
        } else {
          return const LoadingIndicator();
        }
      },
    );
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
  late OrderAccountingLocalizations _localizations;
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
    _selectedCompanyUser =
        (CompanyUser.tryParse(finDocUpdated.otherCompany) ??
        CompanyUser.tryParse(finDocUpdated.otherUser));
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _descriptionController.text = finDocUpdated.description ?? '';
    _pseudoIdController.text = finDoc.pseudoId == null
        ? ''
        : finDoc.pseudoId.toString();
    _selectedRequestType = finDocUpdated.requestType;
    context.read<DataFetchBloc<CompaniesUsers>>().add(
      GetDataEvent<CompaniesUsers>(
        () => context.read<RestClient>().getCompanyUser(
          limit: 100,
          role: Role.unknown,
        ),
      ),
    );
    _finDocBloc = context.read<FinDocBloc>();
    classificationId = context.read<String>();
    _authBloc = context.read<AuthBloc>();
    user = _authBloc.state.authenticate?.user as User;
    if (finDoc.description != null) {
      try {
        Map jsonDescription = finDoc.description != null
            ? jsonDecode(finDoc.description!)
            : {};
        _telephoneController.text = jsonDescription['Telephone_Number'] ?? '';
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
    _localizations = OrderAccountingLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.all(10), // need for width
      key: const Key("RequestDialog"),
      child: SingleChildScrollView(
        key: const Key('listView2'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: popUp(
          context: context,
          height: 650,
          title:
              "${finDoc.sales ? _localizations.incoming : _localizations.outgoing} "
              "${_localizations.request} #${finDoc.pseudoId ?? _localizations.newItem}",
          child: BlocConsumer<FinDocBloc, FinDocState>(
            listenWhen: (previous, current) =>
                previous.status == FinDocStatus.loading,
            listener: (context, state) {
              if (state.status == FinDocStatus.success) {
                // Return the updated finDoc to the parent so it can update the list
                Navigator.of(context).pop(widget.finDoc);
              }
              if (state.status == FinDocStatus.failure) {
                HelperFunctions.showMessage(
                  context,
                  '${state.message}',
                  Colors.red,
                );
              }
            },
            builder: (context, state) {
              return classificationId == 'AppHealth'
                  ? healthRequestForm(
                      state,
                      requestDialogFormKey,
                      isPhone,
                      user,
                    )
                  : requestForm(state, requestDialogFormKey);
            },
          ),
        ),
      ),
    );
  }

  Widget healthRequestForm(
    FinDocState state,
    GlobalKey<FormState> requestDialogFormKey,
    bool isPhone,
    User user,
  ) {
    var companyLabel = _localizations.company;
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
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Text("Enter your request for ${user.firstName} ${user.lastName}"),
            const SizedBox(height: 10),
            if (finDoc.requestId != null &&
                finDoc.otherUser?.partyId != user.partyId)
              BlocBuilder<
                DataFetchBloc<CompaniesUsers>,
                DataFetchState<CompaniesUsers>
              >(
                builder: (context, state) {
                  switch (state.status) {
                    case DataFetchStatus.success:
                      final companyUsers =
                          (state.data as CompaniesUsers).companiesUsers;
                      return Autocomplete<CompanyUser>(
                        key: const Key('otherCompanyUser'),
                        initialValue: TextEditingValue(
                          text: _selectedCompanyUser != null
                              ? ' ${_selectedCompanyUser!.name}[${_selectedCompanyUser!.pseudoId}]'
                              : '',
                        ),
                        displayStringForOption: (CompanyUser u) =>
                            ' ${u.name}[${u.pseudoId}]',
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text
                              .toLowerCase()
                              .trim();
                          if (query.isEmpty) return companyUsers;
                          return companyUsers.where((cu) {
                            final display = ' ${cu.name}[${cu.pseudoId}]'
                                .toLowerCase();
                            return display.contains(query);
                          }).toList();
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextFormField(
                                key: const Key('otherCompanyUserField'),
                                enabled: !readOnly,
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: companyLabel,
                                ),
                                onFieldSubmitted: (_) => onFieldSubmitted(),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? _localizations.selectRequester
                                    : null,
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
                                  itemBuilder: (context, idx) {
                                    final cu = options.elementAt(idx);
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        ' ${cu.name}[${cu.pseudoId}]',
                                      ),
                                      onTap: () => onSelected(cu),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        onSelected: (CompanyUser newValue) {
                          setState(() {
                            _selectedCompanyUser = newValue;
                          });
                        },
                      );
                    case DataFetchStatus.failure:
                      return FatalErrorForm(
                        message: _localizations.serverProblem,
                      );
                    default:
                      return const Center(child: LoadingIndicator());
                  }
                },
              ),
            const SizedBox(height: 10),
            if (finDoc.requestId != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('pseudoId'),
                      enabled: !readOnly,
                      decoration: InputDecoration(labelText: _localizations.id),
                      controller: _pseudoIdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<FinDocStatusVal>(
                      key: const Key('statusDropDown'),
                      decoration: InputDecoration(
                        labelText: _localizations.status,
                      ),
                      initialValue: _updatedStatus,
                      validator: (value) =>
                          value == null ? _localizations.fieldRequired : null,
                      items:
                          FinDocStatusVal.validStatusList(
                                finDoc.status ?? FinDocStatusVal.created,
                              )
                              .map(
                                (label) => DropdownMenuItem<FinDocStatusVal>(
                                  value: label,
                                  child: Text(label.name),
                                ),
                              )
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
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('postalCode'),
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: _localizations.postalCodeCare,
              ),
              controller: _postalController,
              //keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('telephone'),
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: _localizations.telephoneNumberQuestion,
              ),
              controller: _telephoneController,
              //keyboardType: _telephoneController.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('care'),
                    initialValue: selectedCare,
                    decoration: InputDecoration(
                      labelText: _localizations.careTypeQuestion,
                    ),
                    validator: (value) =>
                        value == null ? _localizations.fieldRequired : null,
                    items: [
                      DropdownMenuItem<String>(
                        value: 'resCare',
                        child: Text(_localizations.residentialCare),
                      ),
                      DropdownMenuItem<String>(
                        value: 'homeCare',
                        child: Text(_localizations.homeCare),
                      ),
                      DropdownMenuItem<String>(
                        value: 'stCare',
                        child: Text(_localizations.shortTermCare),
                      ),
                      DropdownMenuItem<String>(
                        value: 'retLiving',
                        child: Text(_localizations.retirementLiving),
                      ),
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
                    initialValue: selectedForWhom,
                    decoration: InputDecoration(
                      labelText: _localizations.careForWhomQuestion,
                    ),
                    validator: (value) =>
                        value == null ? _localizations.fieldRequired : null,
                    items: [
                      DropdownMenuItem<String>(
                        value: 'mySelf',
                        child: Text(_localizations.myself),
                      ),
                      DropdownMenuItem<String>(
                        value: 'myParent',
                        child: Text(_localizations.myParent),
                      ),
                      DropdownMenuItem<String>(
                        value: 'myPartner',
                        child: Text(_localizations.myPartner),
                      ),
                      DropdownMenuItem<String>(
                        value: 'myChild',
                        child: Text(_localizations.myChild),
                      ),
                      DropdownMenuItem<String>(
                        value: 'myClient',
                        child: Text(_localizations.myClient),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Other',
                        child: Text(_localizations.other),
                      ),
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
                    initialValue: selectedTimeframe,
                    decoration: InputDecoration(
                      labelText: _localizations.timeframeQuestion,
                    ),
                    validator: (value) =>
                        value == null ? _localizations.fieldRequired : null,
                    items: [
                      DropdownMenuItem<String>(
                        value: 'unSure',
                        child: Text(_localizations.notSure),
                      ),
                      DropdownMenuItem<String>(
                        value: 'shortTerm',
                        child: Text(_localizations.shortTerm),
                      ),
                      DropdownMenuItem<String>(
                        value: 'longTerm',
                        child: Text(_localizations.longTerm),
                      ),
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
                    initialValue: selectedHowSoon,
                    decoration: InputDecoration(
                      labelText: _localizations.howSoonCareQuestion,
                    ),
                    validator: (value) =>
                        value == null ? _localizations.fieldRequired : null,
                    items: [
                      DropdownMenuItem<String>(
                        value: 'asap',
                        child: Text(_localizations.asap),
                      ),
                      DropdownMenuItem<String>(
                        value: '3Months',
                        child: Text(_localizations.withinThreeMonths),
                      ),
                      DropdownMenuItem<String>(
                        value: '6Months',
                        child: Text(_localizations.withinSixMonths),
                      ),
                      DropdownMenuItem<String>(
                        value: 'moreMonths',
                        child: Text(_localizations.moreThanSixMonths),
                      ),
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
              initialValue: selectedStatus,
              decoration: InputDecoration(
                labelText: _localizations.acatStatusQuestion,
              ),
              validator: (value) =>
                  value == null ? _localizations.fieldRequired : null,
              items: [
                DropdownMenuItem<String>(
                  value: 'unSure',
                  child: Text(_localizations.notSure),
                ),
                DropdownMenuItem<String>(
                  value: 'yettobestarted',
                  child: Text(_localizations.acatNotStarted),
                ),
                DropdownMenuItem<String>(
                  value: 'inProgress',
                  child: Text(_localizations.acatInProgress),
                ),
                DropdownMenuItem<String>(
                  value: 'complete',
                  child: Text(_localizations.acatComplete),
                ),
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
                '${finDoc.idIsNull() ? _localizations.create : _localizations.update} '
                '${finDocUpdated.docType}',
              ),
              onPressed: () {
                var description = jsonEncode({
                  'CarePostCode': _postalController.text,
                  'Telephone_Number': _telephoneController.text,
                  'TypeOfCare': selectedCare,
                  'CareRelationship': selectedForWhom,
                  'CareTimeframe': selectedTimeframe,
                  'HowSoonCare': selectedHowSoon,
                  'ACAT_Status': selectedStatus,
                });
                if (requestDialogFormKey.currentState!.validate()) {
                  _finDocBloc.add(
                    FinDocUpdate(
                      finDocUpdated.copyWith(
                        requestId: widget.finDoc.requestId,
                        requestType: _selectedRequestType,
                        otherCompany: user.company,
                        otherUser: user,
                        pseudoId: _pseudoIdController.text,
                        description: description,
                        status: _updatedStatus,
                        items: [],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget requestForm(
    FinDocState state,
    GlobalKey<FormState> requestDialogFormKey,
  ) {
    final companyLabel = _localizations.requester;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Form(
        key: requestDialogFormKey,
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('pseudoId'),
                    enabled: !readOnly,
                    decoration: InputDecoration(labelText: _localizations.id),
                    controller: _pseudoIdController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<FinDocStatusVal>(
                    key: const Key('statusDropDown'),
                    decoration: InputDecoration(
                      labelText: _localizations.status,
                    ),
                    initialValue: _updatedStatus,
                    validator: (value) =>
                        value == null ? _localizations.fieldRequired : null,
                    items:
                        FinDocStatusVal.validStatusList(
                              finDoc.status ?? FinDocStatusVal.created,
                            )
                            .map(
                              (label) => DropdownMenuItem<FinDocStatusVal>(
                                value: label,
                                child: Text(label.name),
                              ),
                            )
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
            BlocBuilder<
              DataFetchBloc<CompaniesUsers>,
              DataFetchState<CompaniesUsers>
            >(
              builder: (context, state) {
                switch (state.status) {
                  case DataFetchStatus.success:
                    final companyUsers =
                        (state.data as CompaniesUsers).companiesUsers;
                    return Autocomplete<CompanyUser>(
                      key: const Key('otherCompanyUser'),
                      initialValue: TextEditingValue(
                        text: _selectedCompanyUser != null
                            ? ' ${_selectedCompanyUser!.name}[${_selectedCompanyUser!.pseudoId}]'
                            : '',
                      ),
                      displayStringForOption: (CompanyUser u) =>
                          ' ${u.name}[${u.pseudoId}]',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text
                            .toLowerCase()
                            .trim();
                        if (query.isEmpty) return companyUsers;
                        return companyUsers.where((cu) {
                          final display = ' ${cu.name}[${cu.pseudoId}]'
                              .toLowerCase();
                          return display.contains(query);
                        }).toList();
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextFormField(
                              key: const Key('otherCompanyUserField'),
                              enabled: !readOnly,
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: companyLabel,
                              ),
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? _localizations.selectRequester
                                  : null,
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
                                itemBuilder: (context, idx) {
                                  final cu = options.elementAt(idx);
                                  return ListTile(
                                    dense: true,
                                    title: Text(' ${cu.name}[${cu.pseudoId}]'),
                                    onTap: () => onSelected(cu),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (CompanyUser newValue) {
                        setState(() {
                          _selectedCompanyUser = newValue;
                        });
                      },
                    );
                  case DataFetchStatus.failure:
                    return FatalErrorForm(
                      message: _localizations.serverProblem,
                    );
                  default:
                    return const Center(child: LoadingIndicator());
                }
              },
            ),
            const SizedBox(height: 10),
            IgnorePointer(
              ignoring: readOnly,
              child: DropdownButtonFormField<RequestType>(
                decoration: InputDecoration(
                  labelText: _localizations.requestType,
                ),
                key: const Key('requestType'),
                initialValue: _selectedRequestType,
                items: RequestType.values.map((item) {
                  return DropdownMenuItem<RequestType>(
                    value: item,
                    child: Text(
                      item.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  );
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
              decoration: InputDecoration(
                labelText: _localizations.description,
              ),
              controller: _descriptionController,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('cancelFinDoc'),
                  child: Text(_localizations.cancelRequest),
                  onPressed: () {
                    _finDocBloc.add(
                      FinDocUpdate(
                        finDocUpdated.copyWith(
                          status: FinDocStatusVal.cancelled,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(
                      '${finDoc.idIsNull() ? _localizations.create : _localizations.update} '
                      '${finDocUpdated.docType}',
                    ),
                    onPressed: () {
                      if (requestDialogFormKey.currentState!.validate()) {
                        _finDocBloc.add(
                          FinDocUpdate(
                            finDocUpdated.copyWith(
                              requestId: widget.finDoc.requestId,
                              requestType: _selectedRequestType,
                              otherCompany: _selectedCompanyUser!.getCompany(),
                              otherUser: _selectedCompanyUser!.getUser(),
                              pseudoId: _pseudoIdController.text,
                              description: _descriptionController.text,
                              status: _updatedStatus,
                              items: [],
                            ),
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
