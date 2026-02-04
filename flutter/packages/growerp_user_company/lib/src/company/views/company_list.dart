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

import '../../../growerp_user_company.dart';
import 'company_list_styled_data.dart';

class CompanyList extends StatefulWidget {
  const CompanyList({required this.role, this.mainOnly = false, super.key});
  final Role? role;
  final bool mainOnly;

  @override
  CompanyListState createState() => CompanyListState();
}

class CompanyListState extends State<CompanyList> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final double _scrollThreshold = 200.0;
  late CompanyBloc _companyBloc;
  late UserCompanyLocalizations _localizations;
  List<Company> companies = const <Company>[];
  bool showSearchField = false;
  String searchString = '';
  bool hasReachedMax = false;
  bool _isLoading = true;
  late bool isPhone;
  late double bottom;
  double? right;
  double currentScroll = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.mainOnly) {
      _companyBloc = context.read<CompanyBloc>()
        ..add(CompanyFetch(mainOnly: widget.mainOnly));
    } else {
      switch (widget.role) {
        case Role.supplier:
          _companyBloc = context.read<CompanySupplierBloc>() as CompanyBloc
            ..add(const CompanyFetch());
          break;
        case Role.customer:
          _companyBloc = context.read<CompanyCustomerBloc>() as CompanyBloc
            ..add(const CompanyFetch());
          break;
        case Role.lead:
          _companyBloc = context.read<CompanyLeadBloc>() as CompanyBloc
            ..add(const CompanyFetch());
          break;
        default:
          _companyBloc = context.read<CompanyBloc>()
            ..add(const CompanyFetch(refresh: true));
      }
    }
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    _localizations = UserCompanyLocalizations.of(context)!;
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isAPhone(context) ? 20 : 50);
    return Builder(
      builder: (BuildContext context) {
        Widget tableView() {
          // Build rows for StyledDataTable
          final rows = companies.map((company) {
            final index = companies.indexOf(company);
            return getCompanyListRow(
              context: context,
              company: company,
              index: index,
              bloc: _companyBloc,
            );
          }).toList();

          return StyledDataTable(
            columns: getCompanyListColumns(context),
            rows: rows,
            isLoading: _isLoading && companies.isEmpty,
            scrollController: _scrollController,
            rowHeight: isPhone ? 64 : 56,
            onRowTap: (index) {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return Dismissible(
                    key: const Key('companyItem'),
                    direction: DismissDirection.startToEnd,
                    child: BlocProvider.value(
                      value: _companyBloc,
                      child: CompanyDialog(companies[index]),
                    ),
                  );
                },
              );
            },
          );
        }

        blocListener(context, state) {
          if (state.status == CompanyStatus.success) {
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
          }
        }

        blocBuilder(context, state) {
          // Update loading state
          _isLoading = state.status == CompanyStatus.loading;

          if (state.status == CompanyStatus.failure) {
            return FatalErrorForm(
              message: _localizations.couldNotLoad(widget.role.toString()),
            );
          }

          companies = state.companies;
          hasReachedMax = state.hasReachedMax;
          if (companies.isNotEmpty && _scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollController.jumpTo(currentScroll),
              );
            });
          }

          return Column(
            children: [
              // Filter bar with search
              ListFilterBar(
                searchHint: 'Search ${widget.role?.name ?? 'companies'}...',
                searchController: _searchController,
                onSearchChanged: (value) {
                  searchString = value;
                  _companyBloc.add(
                    CompanyFetch(
                      refresh: true,
                      searchString: value,
                      mainOnly: widget.mainOnly,
                    ),
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
                              heroTag: "companybtn2",
                              onPressed: () async {
                                await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                      value: _companyBloc,
                                      child: CompanyDialog(
                                        Company(
                                          partyId: '_NEW_',
                                          role: widget.role,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              tooltip: _localizations.addNew,
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 10),
                            if (widget.mainOnly)
                              FloatingActionButton(
                                key: const Key("refresh"),
                                heroTag: "companybtn3",
                                onPressed: () async => _companyBloc.add(
                                  CompanyFetch(
                                    refresh: true,
                                    mainOnly: widget.mainOnly,
                                  ),
                                ),
                                tooltip: _localizations.refresh,
                                child: const Icon(Icons.refresh),
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

        if (widget.mainOnly) {
          return BlocConsumer<CompanyBloc, CompanyState>(
            listener: blocListener,
            builder: blocBuilder,
          );
        } else {
          switch (widget.role) {
            case Role.lead:
              return BlocConsumer<CompanyLeadBloc, CompanyState>(
                listener: blocListener,
                builder: blocBuilder,
              );
            case Role.customer:
              return BlocConsumer<CompanyCustomerBloc, CompanyState>(
                listener: blocListener,
                builder: blocBuilder,
              );
            case Role.supplier:
              return BlocConsumer<CompanySupplierBloc, CompanyState>(
                listener: blocListener,
                builder: blocBuilder,
              );
            default:
              return BlocConsumer<CompanyBloc, CompanyState>(
                listener: blocListener,
                builder: blocBuilder,
              );
          }
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
      _companyBloc.add(CompanyFetch(searchString: searchString));
    }
  }
}
