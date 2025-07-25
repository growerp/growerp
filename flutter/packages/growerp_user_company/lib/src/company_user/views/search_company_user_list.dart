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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class SearchCompanyUserList extends StatefulWidget {
  const SearchCompanyUserList({super.key});

  @override
  SearchCompanyUserState createState() => SearchCompanyUserState();
}

class SearchCompanyUserState extends State<SearchCompanyUserList> {
  late DataFetchBloc _companyUserBloc;
  List<CompanyUser> companiesUsers = [];

  @override
  void initState() {
    super.initState();
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(GetDataEvent(
          () => context.read<RestClient>().getCompanyUser(limit: 0)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<CompaniesUsers>, DataFetchState<CompaniesUsers>>(
        listener: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == DataFetchStatus.failure ||
          state.status == DataFetchStatus.success) {
        companiesUsers = (state.data as CompaniesUsers).companiesUsers;
        return CompanyUserSearchDialog(
            companyUserBloc: _companyUserBloc,
            widget: widget,
            companiesUsers: companiesUsers);
      } else {
        return const LoadingIndicator();
      }
    });
  }
}

class CompanyUserSearchDialog extends StatelessWidget {
  const CompanyUserSearchDialog({
    super.key,
    required DataFetchBloc companyUserBloc,
    required this.widget,
    required this.companiesUsers,
  }) : _companyUserBloc = companyUserBloc;

  final DataFetchBloc _companyUserBloc;
  final SearchCompanyUserList widget;
  final List<CompanyUser> companiesUsers;

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Dialog(
        key: const Key('SearchDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
            context: context,
            title: 'Company/User Search ',
            height: 500,
            width: 350,
            child: Column(children: [
              TextFormField(
                  key: const Key('searchField'),
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: "Search input"),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a search value?';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => _companyUserBloc.add(
                      GetDataEvent(() => context
                          .read<RestClient>()
                          .getCompanyUser(limit: 5, searchString: value)))),
              const SizedBox(height: 20),
              const Text('Search results'),
              Expanded(
                  child: ListView.builder(
                      key: const Key('listView'),
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: companiesUsers.length + 2,
                      controller: scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Visibility(
                              visible: companiesUsers.isEmpty,
                              child: const Center(
                                  heightFactor: 20,
                                  child: Text('No search items found (yet)',
                                      key: Key('empty'),
                                      textAlign: TextAlign.center)));
                        }
                        index--;
                        return index >= companiesUsers.length
                            ? const Text('')
                            : Dismissible(
                                key: const Key('searchItem'),
                                direction: DismissDirection.startToEnd,
                                child: ListTile(
                                  title: Text(
                                      "ID: ${companiesUsers[index].pseudoId}\n"
                                      "Name: ${companiesUsers[index].name}",
                                      key: Key("searchResult$index")),
                                  subtitle: companiesUsers[index].company !=
                                          null
                                      ? Text("Organization representative:\n"
                                          "${companiesUsers[index].company!.pseudoId}\n"
                                          "${companiesUsers[index].company!.name}")
                                      : const Text(""),
                                  onTap: () => Navigator.of(context)
                                      .pop(companiesUsers[index]),
                                ));
                      }))
            ])));
  }
}
