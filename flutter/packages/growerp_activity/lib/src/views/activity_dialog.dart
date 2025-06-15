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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../growerp_activity.dart';

class ActivityDialog extends StatefulWidget {
  final Activity activity;
  final CompanyUser? companyUser;
  const ActivityDialog(this.activity, this.companyUser, {super.key});
  @override
  ActivityDialogState createState() => ActivityDialogState();
}

class ActivityDialogState extends State<ActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pseudoIdController = TextEditingController();
  final TextEditingController _assigneeSearchBoxController =
      TextEditingController();
  late ActivityBloc _activityBloc;
  late AuthBloc _authBloc;
  late DataFetchBloc<Users> _assigneeBloc;
  late DataFetchBlocOther<Users> _thirdPartyBloc;
  late ActivityStatus _updatedStatus;
  late final User _originator = _authBloc.state.authenticate!.user!;
  late User _selectedAssignee;
  late User? _selectedThirdParty;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = CustomizableDateTime.current;
    _pseudoIdController.text = widget.activity.pseudoId;
    _nameController.text = widget.activity.activityName;
    _descriptionController.text = widget.activity.description;
    _activityBloc = context.read<ActivityBloc>();
    _authBloc = context.read<AuthBloc>();
    _updatedStatus = widget.activity.statusId ?? ActivityStatus.planning;
    _selectedAssignee = widget.activity.assignee ?? _originator;
    _selectedThirdParty = widget.activity.thirdParty;
    _assigneeBloc = context.read<DataFetchBloc<Users>>()
      ..add(GetDataEvent(() =>
          context.read<RestClient>().getUser(limit: 3, role: Role.company)));
    _thirdPartyBloc = context.read<DataFetchBlocOther<Users>>()
      ..add(GetDataEvent(() =>
          context.read<RestClient>().getUser(limit: 3, role: Role.unknown)));
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<ActivityBloc, ActivityState>(
        listener: (context, state) {
      switch (state.status) {
        case ActivityBlocStatus.success:
          Navigator.of(context).pop();
          break;
        case ActivityBlocStatus.failure:
          HelperFunctions.showMessage(
              context, 'Error: ${state.message}', Colors.red);
          break;
        default:
          const Text("????");
      }
    }, builder: (context, state) {
      switch (state.status) {
        case ActivityBlocStatus.success:
          return Dialog(
              key: const Key('ActivityDialog'),
              insetPadding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: popUp(
                  context: context,
                  title:
                      '${widget.activity.activityType} #${widget.activity.pseudoId.isEmpty ? 'New' : widget.activity.pseudoId}',
                  height: isPhone ? 650 : 550,
                  width: 350,
                  child: _showForm(isPhone)));
        case ActivityBlocStatus.failure:
          return FatalErrorForm(
              message: '${widget.activity.activityType} load problem');
        default:
          return const Center(child: LoadingIndicator());
      }
    });
  }

  Widget _showForm(isPhone) {
    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: CustomizableDateTime.current,
        firstDate: CustomizableDateTime.current,
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
        builder: (BuildContext context, Widget? child) {
          return Theme(
              data: ThemeData(primarySwatch: Colors.green), child: child!);
        },
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }

    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            key: const Key('listView'),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('pseudoId'),
                      decoration: const InputDecoration(labelText: 'Id'),
                      controller: _pseudoIdController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.activity.activityType == ActivityType.todo)
                    Expanded(
                      child: DropdownButtonFormField<ActivityStatus>(
                        key: const Key('statusDropDown'),
                        decoration: const InputDecoration(labelText: 'Status'),
                        value: _updatedStatus,
                        validator: (value) =>
                            value == null ? 'field required' : null,
                        items: ActivityStatus.validActivityStatusList(
                                _updatedStatus)
                            .map((label) => DropdownMenuItem<ActivityStatus>(
                                  value: label,
                                  child: Text(label.status),
                                ))
                            .toList(),
                        onChanged: (ActivityStatus? newValue) {
                          setState(() {
                            _updatedStatus = newValue!;
                          });
                        },
                        isExpanded: true,
                      ),
                    ),
                ],
              ),
              TextFormField(
                key: const Key('name'),
                decoration: InputDecoration(
                    labelText: '${widget.activity.activityType} Name'),
                controller: _nameController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a ${widget.activity.activityType} name?';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('description'),
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                controller: _descriptionController,
              ),
              if (widget.activity.activityType == ActivityType.todo)
                const SizedBox(height: 10),
              if (widget.activity.activityType == ActivityType.todo)
                BlocBuilder<DataFetchBloc<Users>, DataFetchState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case DataFetchStatus.failure:
                        return const FatalErrorForm(
                            message: 'server connection problem');
                      case DataFetchStatus.loading:
                        return const LoadingIndicator();
                      case DataFetchStatus.success:
                        return DropdownSearch<User>(
                            selectedItem: _selectedAssignee,
                            popupProps: PopupProps.menu(
                              isFilterOnline: true,
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                autofocus: true,
                                decoration: const InputDecoration(
                                    labelText: "employee,name"),
                                controller: _assigneeSearchBoxController,
                              ),
                              menuProps: MenuProps(
                                  borderRadius: BorderRadius.circular(20.0)),
                              title: popUp(
                                context: context,
                                title: 'Select employee',
                                height: 50,
                              ),
                            ),
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                        labelText: 'Assignee Employee')),
                            key: const Key('assignee'),
                            itemAsString: (User? u) =>
                                " ${u?.firstName} ${u?.lastName} "
                                "${u?.company!.name}",
                            asyncItems: (String filter) {
                              _assigneeBloc.add(GetDataEvent(() => context
                                  .read<RestClient>()
                                  .getUser(
                                      searchString: filter,
                                      limit: 3,
                                      isForDropDown: true,
                                      role: Role.company)));
                              return Future.delayed(
                                  const Duration(milliseconds: 150), () {
                                return Future.value(
                                    (_assigneeBloc.state.data as Users).users);
                              });
                            },
                            compareFn: (item, sItem) =>
                                item.partyId == sItem.partyId,
                            onChanged: (User? newValue) {
                              setState(() {
                                _selectedAssignee = newValue ?? _originator;
                              });
                            });
                      default:
                        return const Center(child: LoadingIndicator());
                    }
                  },
                ),
              if (widget.activity.activityType == ActivityType.todo ||
                  (widget.activity.activityType == ActivityType.event &&
                      widget.companyUser == null))
                const SizedBox(height: 10),
              if (widget.activity.activityType == ActivityType.todo ||
                  (widget.activity.activityType == ActivityType.event &&
                      widget.companyUser == null))
                BlocBuilder<DataFetchBloc<Users>, DataFetchState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case DataFetchStatus.failure:
                        return const FatalErrorForm(
                            message: 'server connection problem');
                      case DataFetchStatus.loading:
                        return const LoadingIndicator();
                      case DataFetchStatus.success:
                        return DropdownSearch<User>(
                            selectedItem: _selectedThirdParty,
                            popupProps: PopupProps.menu(
                              isFilterOnline: true,
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                autofocus: true,
                                decoration: const InputDecoration(
                                    labelText: "third party,name"),
                                controller: _assigneeSearchBoxController,
                              ),
                              menuProps: MenuProps(
                                  borderRadius: BorderRadius.circular(20.0)),
                              title: popUp(
                                context: context,
                                title: 'Select third party',
                                height: 50,
                              ),
                            ),
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                        labelText: 'ThirdParty')),
                            key: const Key('thirdParty'),
                            itemAsString: (User? u) =>
                                " ${u?.firstName} ${u?.lastName} "
                                "${u?.company!.name}",
                            asyncItems: (String filter) {
                              _thirdPartyBloc.add(GetDataEvent(() => context
                                  .read<RestClient>()
                                  .getUser(
                                      searchString: filter,
                                      limit: 3,
                                      isForDropDown: true,
                                      role: Role.unknown)));
                              return Future.delayed(
                                  const Duration(milliseconds: 150), () {
                                return Future.value(
                                    (_thirdPartyBloc.state.data as Users)
                                        .users);
                              });
                            },
                            compareFn: (item, sItem) =>
                                item.partyId == sItem.partyId,
                            onChanged: (User? newValue) {
                              setState(() {
                                _selectedThirdParty = newValue;
                              });
                            });
                      default:
                        return const Center(child: LoadingIndicator());
                    }
                  },
                ),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Estimated start date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: Row(children: [
                  Expanded(
                      child: Center(
                          child: Text(
                    "${_selectedDate.toLocal()}".split(' ')[0],
                    key: const Key('date'),
                  ))),
                  OutlinedButton(
                    key: const Key('setDate'),
                    onPressed: () => selectDate(context),
                    child: const Text(' Update'),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                if (widget.activity.activityId.isNotEmpty &&
                    widget.activity.activityType == ActivityType.todo)
                  OutlinedButton(
                      key: const Key('TimeEntries'),
                      child: const Text('TimeEntries'),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _activityBloc,
                                  child: TimeEntryListDialog(
                                      widget.activity.activityId,
                                      widget.activity.timeEntries));
                            });
                      }),
                const SizedBox(width: 10),
                Expanded(
                    child: OutlinedButton(
                        key: const Key('update'),
                        child: Text(widget.activity.activityId.isEmpty
                            ? 'Create'
                            : 'Update'),
                        onPressed: () async {
                          if (widget.companyUser != null &&
                              widget.activity.activityType ==
                                  ActivityType.event) {
                            _selectedThirdParty = widget.companyUser!.getUser();
                          }
                          if (_formKey.currentState!.validate()) {
                            _activityBloc.add(ActivityUpdate(
                              widget.activity.copyWith(
                                activityId: widget.activity.activityId,
                                pseudoId: _pseudoIdController.text,
                                activityName: _nameController.text,
                                description: _descriptionController.text,
                                statusId: _updatedStatus,
                                assignee: _selectedAssignee,
                                thirdParty: _selectedThirdParty,
                              ),
                            ));
                          }
                        })),
              ]),
            ])));
  }
}
