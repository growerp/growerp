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
import '../company.dart';
import '../widgets/widgets.dart';

class CompanyListForm extends StatelessWidget {
  final Role? role;
  const CompanyListForm({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    Widget companyList = RepositoryProvider.value(
        value: restClient,
        child: CompanyList(
          key: key,
          role: role,
        ));
    AuthBloc authBloc = context.read<AuthBloc>();
    switch (role) {
      case Role.lead:
        return BlocProvider<CompanyLeadBloc>(
            create: (context) => CompanyBloc(
                  restClient,
                  role,
                  authBloc,
                )..add(const CompanyFetch()),
            child: companyList);
      case Role.customer:
        return BlocProvider<CompanyCustomerBloc>(
            create: (context) => CompanyBloc(restClient, role, authBloc)
              ..add(const CompanyFetch()),
            child: companyList);
      case Role.supplier:
        return BlocProvider<CompanySupplierBloc>(
            create: (context) => CompanyBloc(restClient, role, authBloc)
              ..add(const CompanyFetch()),
            child: companyList);
      default:
        return BlocProvider<CompanyBloc>(
            create: (context) => CompanyBloc(restClient, role, authBloc)
              ..add(const CompanyFetch()),
            child: companyList);
    }
  }
}

class CompanyList extends StatefulWidget {
  const CompanyList({super.key, required this.role});

  final Role? role;

  @override
  CompanyListState createState() => CompanyListState();
}

class CompanyListState extends State<CompanyList> {
  final ScrollController _scrollController = ScrollController();
  final double _scrollThreshold = 200.0;
  late CompanyBloc _companyBloc;
  late RestClient repos;
  List<Company> companies = const <Company>[];
  bool showSearchField = false;
  String searchString = '';
  bool isLoading = false;
  bool hasReachedMax = false;
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    repos = context.read<RestClient>();
    switch (widget.role) {
      case Role.supplier:
        _companyBloc = context.read<CompanySupplierBloc>() as CompanyBloc;
        break;
      case Role.customer:
        _companyBloc = context.read<CompanyCustomerBloc>() as CompanyBloc;
        break;
      case Role.lead:
        _companyBloc = context.read<CompanyLeadBloc>() as CompanyBloc;
        break;
      default:
        _companyBloc = context.read<CompanyBloc>();
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Builder(builder: (BuildContext context) {
      Widget showForm(state) {
        return Column(
          children: [
            CompanyListHeader(
                isPhone: isPhone, role: widget.role, companyBloc: _companyBloc),
            Expanded(
              child: RefreshIndicator(
                  onRefresh: (() async =>
                      _companyBloc.add(const CompanyFetch(refresh: true))),
                  child: ListView.builder(
                    key: const Key('listView'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: hasReachedMax
                        ? companies.length + 1
                        : companies.length + 2,
                    controller: _scrollController,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Visibility(
                            visible: companies.isEmpty,
                            child: const Center(
                                heightFactor: 20,
                                child: Text("no records found!",
                                    key: Key('empty'),
                                    textAlign: TextAlign.center)));
                      }
                      index--;
                      return index >= companies.length
                          ? const BottomLoader()
                          : Dismissible(
                              key: const Key('companyItem'),
                              direction: DismissDirection.startToEnd,
                              child: RepositoryProvider.value(
                                  value: repos,
                                  child: BlocProvider.value(
                                      value: _companyBloc,
                                      child: CompanyListItem(
                                          role: widget.role,
                                          company: companies[index],
                                          index: index))));
                    },
                  )),
            ),
          ],
        );
      }

      blocListener(context, state) {
        if (state.status == CompanyStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == CompanyStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      }

      blocBuilder(context, state) {
        if (state.status == CompanyStatus.failure) {
          return FatalErrorForm(
              message: "Could not load ${widget.role.toString()}s!");
        }
        if (state.status == CompanyStatus.success) {
          isLoading = false;
          companies = state.companies;
          hasReachedMax = state.hasReachedMax;
          return Scaffold(
              floatingActionButton: FloatingActionButton(
                  key: const Key("addNew"),
                  onPressed: () async {
                    await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider.value(
                              value: _companyBloc,
                              child: CompanyDialog(Company(
                                role: widget.role,
                              )));
                        });
                  },
                  tooltip: 'Add New',
                  child: const Icon(Icons.add)),
              body: showForm(state));
        }
        isLoading = true;
        return const LoadingIndicator();
      }

      switch (widget.role) {
        case Role.lead:
          return BlocConsumer<CompanyLeadBloc, CompanyState>(
              listener: blocListener, builder: blocBuilder);
        case Role.customer:
          return BlocConsumer<CompanyCustomerBloc, CompanyState>(
              listener: blocListener, builder: blocBuilder);
        case Role.supplier:
          return BlocConsumer<CompanySupplierBloc, CompanyState>(
              listener: blocListener, builder: blocBuilder);
        default:
          return BlocConsumer<CompanyBloc, CompanyState>(
              listener: blocListener, builder: blocBuilder);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > 0 && maxScroll - currentScroll <= _scrollThreshold) {
      _companyBloc.add(CompanyFetch(searchString: searchString));
    }
  }
}
