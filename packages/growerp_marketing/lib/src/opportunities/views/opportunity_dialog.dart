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
import '../models/models.dart';
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
  late APIRepository repos;
  late OpportunityBloc _opportunityBloc;

  @override
  void initState() {
    super.initState();
    repos = context.read<APIRepository>();
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
    int columns = ResponsiveWrapper.of(context).isSmallerThan(TABLET) ? 1 : 2;
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
    Future<List<User>> getData(
        List<UserGroup> userGroups, String filter) async {
      ApiResult<List<User>> result = await repos.getUser(
          userGroups: userGroups, filter: _leadSearchBoxController.text);
      return result.when(
          success: (data) => data,
          failure: (_) => [User(lastName: 'get data error!')]);
    }

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
        maxLines: 5,
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
      DropdownSearch<User>(
        selectedItem: _selectedLead,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            autofocus: true,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
            ),
            controller: _leadSearchBoxController,
          ),
          menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
          title: Container(
              height: 50,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  )),
              child: const Center(
                  child: Text('Select lead',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )))),
        ),
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Lead',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
        ),
        showClearButton: true,
        key: const Key('lead'),
        itemAsString: (User? u) => "${u?.firstName} ${u?.lastName} "
            "${u?.companyName}",
        asyncItems: (String? filter) =>
            getData([UserGroup.Lead], _leadSearchBoxController.text),
        onChanged: (User? newValue) {
          _selectedLead = newValue;
        },
      ),
      DropdownSearch<User>(
          selectedItem: _selectedAccount,
          popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                ),
                controller: _accountSearchBoxController,
              ),
              menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
              title: Container(
                height: 50,
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorDark,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    )),
                child: const Center(
                  child: Text(
                    'Select employee',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
          dropdownSearchDecoration: InputDecoration(
            labelText: 'Account Employee',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
          ),
          showClearButton: true,
          key: const Key('employee'),
          itemAsString: (User? u) => "${u?.firstName} ${u?.lastName} "
              "${u?.companyName}",
          asyncItems: (String? filter) => getData(
              [UserGroup.Employee, UserGroup.Admin],
              _accountSearchBoxController.text),
          onChanged: (User? newValue) {
            _selectedAccount = newValue;
          }),
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
    if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET)) {
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
      column.add(Padding(padding: const EdgeInsets.all(10), child: widgets[i]));
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
