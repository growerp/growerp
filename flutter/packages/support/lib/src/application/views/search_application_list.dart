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

import '../blocs/application_bloc.dart';

class SearchApplicationList extends StatefulWidget {
  const SearchApplicationList({super.key});
  @override
  SearchApplicationListState createState() => SearchApplicationListState();
}

class SearchApplicationListState extends State<SearchApplicationList> {
  final _searchController = TextEditingController();
  late ApplicationBloc _applicationBloc;

  @override
  void initState() {
    super.initState();
    _applicationBloc = context.read<ApplicationBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationBloc, ApplicationState>(
        listener: (context, state) {},
        builder: (context, state) {
          switch (state.status) {
            case ApplicationStatus.failure:
              return const Center(child: Text('failed to fetch applications'));
            case ApplicationStatus.success:
              return Dialog(
                  key: const Key('SearchApplicationDialog'),
                  insetPadding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: popUp(
                      context: context,
                      child: _showSearchForm(state.applications),
                      title: 'Search Application',
                      height: 400,
                      width: 350));
            default:
              return const Center(child: LoadingIndicator());
          }
        });
  }

  Widget _showSearchForm(List<Application> applications) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: TextFormField(
          key: const Key('search'),
          decoration: const InputDecoration(labelText: 'Search'),
          controller: _searchController,
          onChanged: (text) {
            _applicationBloc.add(ApplicationFetch(searchString: text));
          },
        )),
      ]),
      const SizedBox(height: 10),
      Expanded(
          child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: applications.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(applications[index]);
                    },
                    child: Card(
                        child: Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                              "${applications[index].applicationId} ${applications[index].version}"),
                          subtitle: Text(applications[index].backendUrl ?? ''),
                        )
                      ],
                    )));
              }))
    ]);
  }
}
