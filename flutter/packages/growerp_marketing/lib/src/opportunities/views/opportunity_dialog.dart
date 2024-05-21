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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/opportunity_bloc.dart';

class OpportunityDialog extends StatefulWidget {
  final Opportunity opportunity;
  const OpportunityDialog(this.opportunity, {super.key});
  @override
  OpportunityDialogState createState() => OpportunityDialogState();
}

class OpportunityDialogState extends State<OpportunityDialog> {
  final _formKeyOpportunity = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estAmountController = TextEditingController();
  final _estProbabilityController = TextEditingController();
  final _estNextStepController = TextEditingController();
  final _leadSearchBoxController = TextEditingController();
  final _accountSearchBoxController = TextEditingController();

  String? _selectedStageId;
  User? _selectedAccount;
  User? _selectedLead;
  late OpportunityBloc _opportunityBloc;
  late DataFetchBloc<Users> _employeeBloc;
  late DataFetchBlocOther<Users> _leadBloc;

  @override
  void initState() {
    super.initState();
    _employeeBloc = context.read<DataFetchBloc<Users>>()
      ..add(GetDataEvent(() =>
          context.read<RestClient>().getUser(limit: 3, role: Role.company)));
    _leadBloc = context.read<DataFetchBlocOther<Users>>()
      ..add(GetDataEvent(
          () => context.read<RestClient>().getUser(limit: 3, role: Role.lead)));
    _opportunityBloc = context.read<OpportunityBloc>();
    _nameController.text = widget.opportunity.opportunityName ?? '';
    _descriptionController.text = widget.opportunity.description ?? '';
    _estAmountController.text = widget.opportunity.estAmount != null
        ? widget.opportunity.estAmount.toString()
        : '';
    _estProbabilityController.text = widget.opportunity.estProbability != null
        ? widget.opportunity.estProbability.toString()
        : '';
    _estNextStepController.text = widget.opportunity.nextStep ?? '';
    if (widget.opportunity.leadUser != null) {
      _selectedLead = widget.opportunity.leadUser;
    }
    if (widget.opportunity.employeeUser != null) {
      _selectedAccount = widget.opportunity.employeeUser;
    }
    if (widget.opportunity.stageId != null) {
      _selectedStageId = widget.opportunity.stageId ?? opportunityStages[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    int columns = ResponsiveBreakpoints.of(context).isMobile ? 1 : 2;
    return BlocListener<OpportunityBloc, OpportunityState>(
        listener: (context, state) async {
          switch (state.status) {
            case OpportunityStatus.success:
              Navigator.of(context).pop();
              break;
            case OpportunityStatus.failure:
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
                key: const Key('OpportunityDialog'),
                insetPadding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                    context: context,
                    title:
                        "Opportunity #${widget.opportunity.opportunityId.isEmpty ? " New" : widget.opportunity.opportunityId}",
                    width: columns.toDouble() * 400,
                    height: 1 / columns.toDouble() * 1000,
                    child: _opportunityForm()))));
  }

  Widget _opportunityForm() {
    List<Widget> widgets = [
      TextFormField(
        key: const Key('name'),
        decoration: const InputDecoration(labelText: 'Opportunity Name'),
        controller: _nameController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a opportunity name?' : null;
        },
      ),
      TextFormField(
        key: const Key('description'),
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Description'),
        controller: _descriptionController,
      ),
      TextFormField(
        key: const Key('estAmount'),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
        ],
        decoration: const InputDecoration(labelText: 'Expected revenue Amount'),
        controller: _estAmountController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter an amount?' : null;
        },
      ),
      TextFormField(
        key: const Key('estProbability'),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: const InputDecoration(labelText: 'Estimated Probabilty %'),
        controller: _estProbabilityController,
        validator: (value) {
          return value!.isEmpty
              ? 'Please enter a probability % (1-100)?'
              : null;
        },
      ),
      TextFormField(
        key: const Key('nextStep'),
        decoration: const InputDecoration(labelText: 'Next step'),
        controller: _estNextStepController,
        validator: (value) {
          return value!.isEmpty ? 'Next step?' : null;
        },
      ),
      DropdownButtonFormField<String>(
        key: const Key('stageId'),
        value: _selectedStageId,
        decoration: const InputDecoration(labelText: 'Opportunity Stage'),
        validator: (value) => value == null ? 'field required' : null,
        items: opportunityStages.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: (String? newValue) {
          _selectedStageId = newValue;
        },
        isExpanded: true,
      ),
      BlocBuilder<DataFetchBlocOther<Users>, DataFetchState>(
        builder: (context, state) {
          switch (state.status) {
            case DataFetchStatus.failure:
              return const FatalErrorForm(message: 'server connection problem');
            case DataFetchStatus.loading:
              return LoadingIndicator();
            case DataFetchStatus.success:
              return DropdownSearch<User>(
                selectedItem: _selectedLead,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration: const InputDecoration(labelText: "lead,name"),
                    controller: _leadSearchBoxController,
                  ),
                  menuProps:
                      MenuProps(borderRadius: BorderRadius.circular(20.0)),
                  title: popUp(
                    context: context,
                    title: 'Select Lead',
                    height: 50,
                  ),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration:
                        InputDecoration(labelText: 'Lead')),
                key: const Key('lead'),
                itemAsString: (User? u) => " ${u?.firstName} ${u?.lastName} "
                    "${u?.company!.name}",
                asyncItems: (String filter) {
                  _leadBloc.add(GetDataEvent(() => context
                      .read<RestClient>()
                      .getUser(
                          searchString: filter,
                          limit: 3,
                          isForDropDown: true,
                          role: Role.lead)));
                  return Future.delayed(const Duration(milliseconds: 150), () {
                    return Future.value((_leadBloc.state.data as Users).users);
                  });
                },
                onChanged: (User? newValue) {
                  _selectedLead = newValue;
                },
              );
            default:
              return const Center(child: LoadingIndicator());
          }
        },
      ),
      BlocBuilder<DataFetchBloc<Users>, DataFetchState>(
        builder: (context, state) {
          switch (state.status) {
            case DataFetchStatus.failure:
              return const FatalErrorForm(message: 'server connection problem');
            case DataFetchStatus.loading:
              return LoadingIndicator();
            case DataFetchStatus.success:
              return DropdownSearch<User>(
                  selectedItem: _selectedAccount,
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: "employee,name"),
                      controller: _accountSearchBoxController,
                    ),
                    title: popUp(
                      context: context,
                      title: 'Select employee',
                      height: 50,
                    ),
                  ),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration:
                          InputDecoration(labelText: 'Account Employee')),
                  key: const Key('employee'),
                  itemAsString: (User? u) => " ${u?.firstName} ${u?.lastName} "
                      "${u?.company!.name}",
                  asyncItems: (String filter) {
                    _employeeBloc.add(GetDataEvent(() => context
                        .read<RestClient>()
                        .getUser(
                            searchString: filter,
                            limit: 3,
                            isForDropDown: true,
                            role: Role.company)));
                    return Future.delayed(const Duration(milliseconds: 150),
                        () {
                      return Future.value(
                          (_employeeBloc.state.data as Users).users);
                    });
                  },
                  onChanged: (User? newValue) {
                    _selectedAccount = newValue;
                  });
            default:
              return const Center(child: LoadingIndicator());
          }
        },
      ),
      Row(
        children: [
          Expanded(
              child: ElevatedButton(
                  key: const Key('update'),
                  child: Text(widget.opportunity.opportunityId.isEmpty
                      ? 'Create'
                      : 'Update'),
                  onPressed: () {
                    if (_formKeyOpportunity.currentState!.validate()) {
                      _opportunityBloc.add(OpportunityUpdate(Opportunity(
                        opportunityId: widget.opportunity.opportunityId,
                        opportunityName: _nameController.text,
                        description: _descriptionController.text,
                        estAmount: Decimal.parse(_estAmountController.text),
                        estProbability:
                            Decimal.parse(_estProbabilityController.text),
                        stageId: _selectedStageId,
                        nextStep: _estNextStepController.text,
                        employeeUser: _selectedAccount,
                        leadUser: _selectedLead,
                      )));
                    }
                  }))
        ],
      )
    ];

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    }
    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(widgets[i]);
    }

    return Form(
        key: _formKeyOpportunity,
        child: SingleChildScrollView(
          key: const Key('listView'),
          padding: const EdgeInsets.all(20),
          child: Column(children: (rows.isEmpty ? column : rows)),
        ));
  }
}
