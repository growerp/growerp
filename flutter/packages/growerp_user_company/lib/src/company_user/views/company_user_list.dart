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

// ignore_for_file: exhaustive_cases
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/l10n/generated/user_company_localizations.dart';

import '../../common/common.dart';
import '../company_user.dart';
import 'company_dialog.dart';
import 'company_user_list_styled_data.dart';
import 'user_dialog.dart';

class CompanyUserList extends StatefulWidget {
  const CompanyUserList({required this.role, super.key});
  final Role? role;

  @override
  CompanyUserListState createState() => CompanyUserListState();
}

class CompanyUserListState extends State<CompanyUserList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final double _scrollThreshold = 100.0;
  late CompanyUserBloc _companyUserBloc;
  List<CompanyUser> companiesUsers = const <CompanyUser>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  bool _isLoading = true;
  late bool isPhone;
  int limit =
      (WidgetsBinding
                  .instance
                  .platformDispatcher
                  .views
                  .first
                  .physicalSize
                  .height /
              35)
          .toInt();
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    switch (widget.role) {
      case Role.supplier:
        _companyUserBloc =
            context.read<CompanyUserSupplierBloc>() as CompanyUserBloc
              ..add(const CompanyUserFetch());
      case Role.customer:
        _companyUserBloc =
            context.read<CompanyUserCustomerBloc>() as CompanyUserBloc
              ..add(const CompanyUserFetch());
      case Role.lead:
        _companyUserBloc =
            context.read<CompanyUserLeadBloc>() as CompanyUserBloc
              ..add(const CompanyUserFetch());
      default:
        _companyUserBloc = context.read<CompanyUserBloc>()
          ..add(const CompanyUserFetch(refresh: true));
    }
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    var localizations = UserCompanyLocalizations.of(context)!;
    right = right ?? (isAPhone(context) ? 20 : 50);
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          // Build rows for StyledDataTable
          final rows = companiesUsers.map((companyUser) {
            final index = companiesUsers.indexOf(companyUser);
            return getCompanyUserListRow(
              context: context,
              companyUser: companyUser,
              index: index,
              bloc: _companyUserBloc,
            );
          }).toList();

          return StyledDataTable(
            columns: getCompanyUserListColumns(context),
            rows: rows,
            isLoading: _isLoading && companiesUsers.isEmpty,
            scrollController: _scrollController,
            rowHeight: isPhone ? 64 : 56,
            onRowTap: (index) {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return Dismissible(
                    key: const Key('companyUserItem'),
                    direction: DismissDirection.startToEnd,
                    child: BlocProvider.value(
                      value: _companyUserBloc,
                      child: companiesUsers[index].type == PartyType.company
                          ? ShowCompanyDialog(
                              companiesUsers[index].getCompany()!,
                            )
                          : ShowUserDialog(companiesUsers[index].getUser()!),
                    ),
                  );
                },
              );
            },
          );
        }

        blocListener(context, state) {
          if (state.status == CompanyUserStatus.failure) {
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Colors.red,
            );
          }
          if (state.status == CompanyUserStatus.success) {
            final localizations = UserCompanyLocalizations.of(context)!;
            final translatedMessage = state.message != null
                ? translateUserCompanyBlocMessage(localizations, state.message!)
                : '';
            if (translatedMessage.isNotEmpty) {
              HelperFunctions.showMessage(
                context,
                translatedMessage,
                state.message != null && state.message!.contains('However')
                    ? Colors.yellow
                    : Colors.green,
                seconds: 5,
              );
            }
          }
        }

        blocBuilder(context, state) {
          // Update loading state
          _isLoading = state.status == CompanyUserStatus.loading;

          if (state.status == CompanyUserStatus.failure) {
            return FatalErrorForm(
              message: localizations.couldNotLoad(widget.role.toString()),
            );
          }

          companiesUsers = state.companiesUsers;
          // Only jump to scroll position if the list is not empty and controller is attached
          if (companiesUsers.isNotEmpty && _scrollController.hasClients) {
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
                searchHint:
                    'Search ${widget.role?.name ?? 'companies/users'}...',
                searchController: _searchController,
                onSearchChanged: (value) {
                  searchString = value;
                  _companyUserBloc.add(
                    CompanyUserFetch(refresh: true, searchString: value),
                  );
                },
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FloatingActionButton(
                              key: const Key("addNewCompany"),
                              heroTag: "companUserBtn2",
                              onPressed: () async {
                                await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                      value: _companyUserBloc,
                                      child: CompanyDialog(
                                        Company(
                                          partyId: '_NEW_',
                                          role: widget.role,
                                        ),
                                        dialog: true,
                                      ),
                                    );
                                  },
                                );
                              },
                              tooltip: localizations.addNew,
                              child: Column(
                                children: [
                                  const Icon(Icons.add),
                                  Text(localizations.org),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            FloatingActionButton(
                              key: const Key("addNewUser"),
                              heroTag: "companUserBtn3",
                              onPressed: () async {
                                await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                      value: _companyUserBloc,
                                      child: UserDialog(
                                        User(role: widget.role),
                                      ),
                                    );
                                  },
                                );
                              },
                              tooltip: localizations.addNew,
                              child: Column(
                                children: [
                                  const Icon(Icons.add),
                                  Text(localizations.person),
                                ],
                              ),
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
                                      value: _companyUserBloc,
                                      child: const CompanyUserFilesDialog(),
                                    );
                                  },
                                );
                              },
                              tooltip: localizations.companyUserUpDown,
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
            return BlocConsumer<CompanyUserLeadBloc, CompanyUserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.customer:
            return BlocConsumer<CompanyUserCustomerBloc, CompanyUserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          case Role.supplier:
            return BlocConsumer<CompanyUserSupplierBloc, CompanyUserState>(
              listener: blocListener,
              builder: blocBuilder,
            );
          default:
            return BlocConsumer<CompanyUserBloc, CompanyUserState>(
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
      _companyUserBloc.add(CompanyUserFetch(searchString: searchString));
    }
  }
}
