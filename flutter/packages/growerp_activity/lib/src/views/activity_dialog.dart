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

  late ActivityBloc _activityBloc;
  late AuthBloc _authBloc;
  late ActivityLocalizations _localizations;
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
      ..add(
        GetDataEvent(
          () =>
              context.read<RestClient>().getUser(limit: 3, role: Role.company),
        ),
      );
    _thirdPartyBloc = context.read<DataFetchBlocOther<Users>>()
      ..add(
        GetDataEvent(
          () =>
              context.read<RestClient>().getUser(limit: 3, role: Role.unknown),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = ActivityLocalizations.of(context)!;
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocConsumer<ActivityBloc, ActivityState>(
      listener: (context, state) {
        switch (state.status) {
          case ActivityBlocStatus.success:
            Navigator.of(context).pop();
            break;
          case ActivityBlocStatus.failure:
            HelperFunctions.showMessage(
              context,
              _localizations.activity_error(state.message ?? ''),
              Colors.red,
            );
            break;
          default:
            const Text("????");
        }
      },
      builder: (context, state) {
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
                title: _localizations.activity_title(
                  widget.activity.activityType.toString(),
                  widget.activity.pseudoId.isEmpty
                      ? _localizations.activity_new
                      : widget.activity.pseudoId,
                ),
                height: isPhone ? 650 : 550,
                width: 350,
                child: _showForm(isPhone),
              ),
            );
          case ActivityBlocStatus.failure:
            return FatalErrorForm(
              message: _localizations.activity_loadError(
                widget.activity.activityType.toString(),
              ),
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      },
    );
  }

  Widget _showForm(bool isPhone) {
    Future<void> selectDate(BuildContext context) async {
      // Get locale from LocaleBloc to respect user's language selection
      final localeState = context.read<LocaleBloc>().state;
      final themeState = context.read<ThemeBloc>().state;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: CustomizableDateTime.current,
        firstDate: CustomizableDateTime.current,
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
        locale: localeState.locale,
        builder: (BuildContext context, Widget? child) {
          final isDark = themeState.themeMode == ThemeMode.dark;
          final surfaceColor = isDark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surface;

          return Theme(
            data: isDark
                ? ThemeData.dark(useMaterial3: true).copyWith(
                    primaryColor: Colors.green,
                    colorScheme: ColorScheme.dark(
                      primary: Colors.green,
                      secondary: Colors.green,
                      surface: surfaceColor,
                    ),
                    scaffoldBackgroundColor: surfaceColor,
                  )
                : ThemeData.light(useMaterial3: true).copyWith(
                    primaryColor: Colors.green,
                    colorScheme: ColorScheme.light(
                      primary: Colors.green,
                      secondary: Colors.green,
                      surface: surfaceColor,
                    ),
                  ),
            child: child!,
          );
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('pseudoId'),
                    decoration: InputDecoration(
                      labelText: _localizations.activity_id,
                    ),
                    controller: _pseudoIdController,
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.activity.activityType == ActivityType.todo)
                  Expanded(
                    child: DropdownButtonFormField<ActivityStatus>(
                      key: const Key('statusDropDown'),
                      decoration: InputDecoration(
                        labelText: _localizations.activity_status,
                      ),
                      initialValue: _updatedStatus,
                      validator: (value) => value == null
                          ? _localizations.activity_fieldRequired
                          : null,
                      items:
                          ActivityStatus.validActivityStatusList(_updatedStatus)
                              .map(
                                (label) => DropdownMenuItem<ActivityStatus>(
                                  value: label,
                                  child: Text(label.status),
                                ),
                              )
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
                labelText: _localizations.activity_nameError(
                  widget.activity.activityType.toString(),
                ),
              ),
              controller: _nameController,
              validator: (value) {
                if (value!.isEmpty) {
                  return _localizations.activity_nameError(
                    widget.activity.activityType.toString(),
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('description'),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _localizations.activity_description,
              ),
              controller: _descriptionController,
            ),
            if (widget.activity.activityType == ActivityType.todo)
              const SizedBox(height: 10),
            if (widget.activity.activityType == ActivityType.todo)
              BlocBuilder<DataFetchBloc<Users>, DataFetchState<Users>>(
                builder: (context, state) {
                  switch (state.status) {
                    case DataFetchStatus.failure:
                      return FatalErrorForm(
                        message: _localizations.activity_serverError,
                      );
                    case DataFetchStatus.loading:
                      return const LoadingIndicator();
                    case DataFetchStatus.success:
                      return AutocompleteLabel<User>(
                        key: const Key('assignee'),
                        label: _localizations.activity_assignee,
                        initialValue: _selectedAssignee,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          _assigneeBloc.add(
                            GetDataEvent(
                              () => context.read<RestClient>().getUser(
                                searchString: textEditingValue.text,
                                limit: 3,
                                isForDropDown: true,
                                role: Role.company,
                              ),
                            ),
                          );
                          return Future.delayed(
                            const Duration(milliseconds: 150),
                            () {
                              return (_assigneeBloc.state.data as Users).users;
                            },
                          );
                        },
                        displayStringForOption: (User u) =>
                            " ${u.firstName} ${u.lastName} "
                            "${u.company?.name ?? ''}",
                        onSelected: (User? newValue) {
                          setState(() {
                            _selectedAssignee = newValue ?? _originator;
                          });
                        },
                      );
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
              BlocBuilder<DataFetchBloc<Users>, DataFetchState<Users>>(
                builder: (context, state) {
                  switch (state.status) {
                    case DataFetchStatus.failure:
                      return FatalErrorForm(
                        message: _localizations.activity_serverError,
                      );
                    case DataFetchStatus.loading:
                      return const LoadingIndicator();
                    case DataFetchStatus.success:
                      return AutocompleteLabel<User>(
                        key: const Key('thirdParty'),
                        label: _localizations.activity_thirdParty,
                        initialValue: _selectedThirdParty,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          _thirdPartyBloc.add(
                            GetDataEvent(
                              () => context.read<RestClient>().getUser(
                                searchString: textEditingValue.text,
                                limit: 3,
                                isForDropDown: true,
                                role: Role.unknown,
                              ),
                            ),
                          );
                          return Future.delayed(
                            const Duration(milliseconds: 150),
                            () {
                              return (_thirdPartyBloc.state.data as Users)
                                  .users;
                            },
                          );
                        },
                        displayStringForOption: (User u) =>
                            " ${u.firstName} ${u.lastName} "
                            "${u.company?.name ?? ''}",
                        onSelected: (User? newValue) {
                          setState(() {
                            _selectedThirdParty = newValue;
                          });
                        },
                      );
                    default:
                      return const Center(child: LoadingIndicator());
                  }
                },
              ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText: _localizations.activity_startDate,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "${_selectedDate.toLocal()}".split(' ')[0],
                        key: const Key('date'),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('setDate'),
                    onPressed: () => selectDate(context),
                    child: Text(_localizations.activity_update),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (widget.activity.activityId.isNotEmpty &&
                    widget.activity.activityType == ActivityType.todo)
                  OutlinedButton(
                    key: const Key('TimeEntries'),
                    child: Text(_localizations.activity_timeEntries),
                    onPressed: () async {
                      await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider.value(
                            value: _activityBloc,
                            child: TimeEntryListDialog(
                              widget.activity.activityId,
                              widget.activity.timeEntries,
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(
                      widget.activity.activityId.isEmpty
                          ? _localizations.activity_create
                          : _localizations.activity_update,
                    ),
                    onPressed: () async {
                      if (widget.companyUser != null &&
                          widget.activity.activityType == ActivityType.event) {
                        _selectedThirdParty = widget.companyUser!.getUser();
                      }
                      if (_formKey.currentState!.validate()) {
                        _activityBloc.add(
                          ActivityUpdate(
                            widget.activity.copyWith(
                              activityId: widget.activity.activityId,
                              pseudoId: _pseudoIdController.text,
                              activityName: _nameController.text,
                              description: _descriptionController.text,
                              statusId: _updatedStatus,
                              assignee: _selectedAssignee,
                              thirdParty: _selectedThirdParty,
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
