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

class SearchFinDocList extends StatefulWidget {
  const SearchFinDocList(
      {super.key, required this.sales, required this.docType});
  final bool sales;
  final FinDocType docType;

  @override
  SearchFinDocState createState() => SearchFinDocState();
}

class SearchFinDocState extends State<SearchFinDocList> {
  late DataFetchBloc _finDocBloc;
  List<FinDoc> finDocs = [];

  @override
  void initState() {
    super.initState();
    _finDocBloc = context.read<DataFetchBloc<FinDocs>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getFinDoc(limit: 0)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataFetchBloc<FinDocs>, DataFetchState<FinDocs>>(
        listener: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == DataFetchStatus.failure) {
        return Center(
            child: Text('failed to fetch search items: ${state.message}'));
      }
      if (state.status == DataFetchStatus.success) {
        finDocs = (state.data as FinDocs).finDocs;
      }
      return Stack(
        children: [
          FinDocSearchDialog(
              finDocBloc: _finDocBloc, widget: widget, finDocs: finDocs),
          if (state.status == DataFetchStatus.loading) const LoadingIndicator(),
        ],
      );
    });
  }
}

class FinDocSearchDialog extends StatelessWidget {
  const FinDocSearchDialog({
    super.key,
    required DataFetchBloc finDocBloc,
    required this.widget,
    required this.finDocs,
  }) : _finDocBloc = finDocBloc;

  final DataFetchBloc _finDocBloc;
  final SearchFinDocList widget;
  final List<FinDoc> finDocs;

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
            title: '${widget.docType} Search ',
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
                  onFieldSubmitted: (value) {
                    _finDocBloc.add(GetDataEvent(() => context
                        .read<RestClient>()
                        .getFinDoc(
                            docType: widget.docType,
                            sales: widget.sales,
                            limit: 5,
                            searchString: value)));
                    Future.delayed(const Duration(milliseconds: 150));
                  }),
              const SizedBox(height: 20),
              const Text('Search results'),
              Expanded(
                  child: ListView.builder(
                      key: const Key('listView'),
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: finDocs.length + 2,
                      controller: scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Visibility(
                              visible: finDocs.isEmpty,
                              child: const Center(
                                  heightFactor: 20,
                                  child: Text('No search items found (yet)',
                                      key: Key('empty'),
                                      textAlign: TextAlign.center)));
                        }
                        index--;
                        if (index >= finDocs.length) {
                          return const Text(' ');
                        } else {
                          var party = toCompanyUser(
                              finDocs[index].otherCompany ??
                                  finDocs[index].otherUser);
                          return Dismissible(
                              key: const Key('searchItem'),
                              direction: DismissDirection.startToEnd,
                              child: ListTile(
                                title: Text(
                                    "ID: ${finDocs[index].pseudoId}  "
                                    "Date: ${finDocs[index].creationDate.dateOnly()}",
                                    key: Key("searchResult$index")),
                                subtitle: Column(children: [
                                  if (finDocs[index].docSubType != null)
                                    Text(finDocs[index].docSubType!),
                                  if (party != null)
                                    Text(
                                        "${party.type}: ${party.name ?? '??'} "),
                                ]),
                                onTap: () =>
                                    Navigator.of(context).pop(finDocs[index]),
                              ));
                        }
                      }))
            ])));
  }
}
