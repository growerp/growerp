
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_user_company.dart';
import 'user_list_styled_data.dart';

class UserList extends StatefulWidget {
  const UserList({super.key, this.role});
  final Role? role;

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UserList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final double _scrollThreshold = 100.0;
  late UserBloc _userBloc;
  late AuthBloc _authBloc;
  late UserCompanyLocalizations _localizations;
  List<User> users = const <User>[];
  bool showSearchField = false;
  String searchString = '';

  /// lead list filter, null shows all leads
  String? leadStatusFilter;
  bool hasReachedMax = false;
  bool _isLoading = true;
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _authBloc = context.read<AuthBloc>();
    switch (widget.role) {
      case Role.company:
        _userBloc = (context.read<EmployeeBloc>() as UserBloc)
          ..add(const UserFetch(refresh: true));
        break;
      case Role.supplier:
        _userBloc = (context.read<SupplierBloc>() as UserBloc)
          ..add(const UserFetch(refresh: true));
        break;
      case Role.customer:
        _userBloc = (context.read<CustomerBloc>() as UserBloc)
          ..add(const UserFetch(refresh: true));
        break;
      case Role.lead:
        (_userBloc = context.read<LeadBloc>() as UserBloc).add(
          const UserFetch(refresh: true),
        );
        break;
      default:
        _userBloc = (context.read<UserBloc>())
          ..add(const UserFetch(refresh: true));
    }
    bottom = 50;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _searchFocusNode.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _localizations = UserCompanyLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 50);
    return Builder(
      builder: (BuildContext context) {
        final isPhone = ResponsiveBreakpoints.of(context).isMobile;

        Widget tableView() {
          // Build rows for StyledDataTable
          final rows = users.map((user) {
            final index = users.indexOf(user);
            return getUserListRow(
              context: context,
              user: user,
              index: index,
              bloc: _userBloc,
              role: widget.role,
            );
          }).toList();

          return StyledDataTable(
            columns: getUserListColumns(context, role: widget.role),
            rows: rows,
            isLoading: _isLoading && users.isEmpty,
            scrollController: _scrollController,
            rowHeight: isPhone ? 72 : 56,
            onRowTap: (index) async {
              await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return Dismissible(
                    key: const Key('userItem'),
                    direction: DismissDirection.startToEnd,
                    child: BlocProvider.value(
                      value: _userBloc,
                      child: UserDialogStateFull(user: users[index]),
                    ),
                  );
                },
              );
              _searchFocusNode.requestFocus();
            },
          );
        }

        blocListener(context, state) {
          if (state.status == UserStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
            _searchFocusNode.requestFocus();
          }
          if (state.status == UserStatus.success) {
            final translatedMessage = state.message != null
                ? translateUserCompanyBlocMessage(
                    _localizations,
                    state.message!,
                  )
                : '';
            if (translatedMessage.isNotEmpty) {
              HelperFunctions.showMessage(
                context,
                translatedMessage,
                Colors.green,
              );
            }
            _searchFocusNode.requestFocus();
          }
        }

        blocBuilder(context, state) {
          // Update loading state
          _isLoading = state.status == UserStatus.loading;

          if (state.status == UserStatus.failure) {
            return FatalErrorForm(
              message: "Could not load ${widget.role.toString()}s!",
            );
          }

          users = state.users;
          if (users.isNotEmpty && _scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(currentScroll);
                }
              });
            });
          }
          hasReachedMax = state.hasReachedMax;

          return Column(
            children: [
              // Filter bar with search
              ListFilterBar(
                searchHint: _localizations.searchHintNoun(
                  roleNoun(_localizations, widget.role, _localizations.users),
                ),
                searchController: _searchController,
                focusNode: _searchFocusNode,
                onSearchChanged: (value) {
                  searchString = value;
                  _userBloc.add(
                    UserSearchChanged(
                      searchString: value,
                      customerStatus: leadStatusFilter,
                      userGroup: null,
                      partyId: null,
                    ),
                  );
                },
                filters: widget.role != Role.lead
                    ? null
                    : [
                        FilterDropdown<String>(
                          key: const Key('leadStatusFilter'),
                          label: _localizations.leadStatus,
                          value: leadStatusFilter,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(_localizations.leadStatusAll),
                            ),
                            DropdownMenuItem(
                              value: 'CUSTOMER_NEW',
                              child: Text(_localizations.leadStatusNew),
                            ),
                            DropdownMenuItem(
                              value: LeadStatus.assigned.value,
                              child: Text(_localizations.leadStatusAssigned),
                            ),
                            DropdownMenuItem(
                              value: LeadStatus.qualified.value,
                              child: Text(_localizations.leadStatusQualified),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => leadStatusFilter = value);
                            _userBloc.add(
                              UserFetch(
                                refresh: true,
                                searchString: searchString,
                                customerStatus: value,
                              ),
                            );
                          },
                        ),
                      ],
              ),
              // Main content area with StyledDataTable
              Expanded(
                child: Stack(
                  children: [
                    tableView(),
                    Positioned(
                      right: right,
                      bottom: bottom,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            right = right! - details.delta.dx;
                            bottom -= details.delta.dy;
                          });
                        },
                        child: Column(
                          children: [
                            FloatingActionButton(
                              key: const Key("addNewUser"),
                              heroTag: "userBtn2",
                              onPressed: () async {
                                await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                      value: _userBloc,
                                      child: UserDialogStateFull(
                                        user: User(
                                          role: widget.role,
                                          company: widget.role == Role.company
                                              ? _authBloc
                                                    .state
                                                    .authenticate!
                                                    .company
                                              : Company(role: widget.role),
                                        ),
                                      ),
                                    );
                                  },
                                );
                                _searchFocusNode.requestFocus();
                              },
                              tooltip: _localizations.addNew,
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              heroTag: 'companyUserFiles',
                              key: const Key("upDownload"),
                              onPressed: () async {
                                await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                      value: _userBloc,
                                      child: const CompanyUserFilesDialog(),
                                    );
                                  },
                                );
                                _searchFocusNode.requestFocus();
                              },
                              tooltip: UserCompanyLocalizations.of(context)!.companiesUsersUpDownload,
                              child: const Icon(Icons.file_copy),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        switch (widget.role) {
          case Role.lead:
            return BlocConsumer<LeadBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.customer:
            return BlocConsumer<CustomerBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.company:
            return BlocConsumer<EmployeeBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.supplier:
            return BlocConsumer<SupplierBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          default:
            return BlocConsumer<UserBloc, UserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the controller is attached before accessing position properties
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    currentScroll = _scrollController.position.pixels;
    if (!hasReachedMax &&
        currentScroll > 0 &&
        maxScroll - currentScroll <= _scrollThreshold) {
      _userBloc.add(
        UserFetch(searchString: searchString, customerStatus: leadStatusFilter),
      );
    }
  }
}
