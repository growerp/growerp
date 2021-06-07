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
import 'package:core/blocs/@blocs.dart';
import 'package:core/widgets/@widgets.dart';
import 'package:core/helper_functions.dart';
import 'package:models/@models.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

import '@forms.dart';

class AssetsForm extends StatefulWidget {
  const AssetsForm();
  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetsForm> {
  final _scrollController = ScrollController();
  double _scrollThreshold = 200.0;
  late AssetBloc _assetBloc;
  Authenticate? authenticate;
  late int limit;
  late bool search;
  String? searchString;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _assetBloc = BlocProvider.of<AssetBloc>(context);
    search = false;
    limit = 20;
  }

  @override
  Widget build(BuildContext context) {
    limit = (MediaQuery.of(context).size.height / 35).round();
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
        return BlocConsumer<AssetBloc, AssetState>(listener: (context, state) {
          if (state is AssetProblem)
            HelperFunctions.showMessage(
                context, '${state.errorMessage}', Colors.red);
          if (state is AssetSuccess)
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
        }, builder: (context, state) {
          if (state is AssetLoading) return LoadingIndicator();
          if (state is AssetSuccess) {
            List<Asset>? assets = state.assets;
            return ListView.builder(
              itemCount: state.hasReachedMax! && assets!.isNotEmpty
                  ? assets.length + 1
                  : assets!.length + 2,
              controller: _scrollController,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0)
                  return ListTile(
                      onTap: (() {
                        setState(() {
                          search = !search;
                        });
                      }),
                      leading:
                          Image.asset('assets/images/search.png', height: 30),
                      title: search
                          ? Row(children: <Widget>[
                              SizedBox(
                                  width: ResponsiveWrapper.of(context)
                                          .isSmallerThan(TABLET)
                                      ? MediaQuery.of(context).size.width - 250
                                      : MediaQuery.of(context).size.width - 350,
                                  child: TextField(
                                    textInputAction: TextInputAction.go,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      hintText:
                                          "search in ID, name and description...",
                                    ),
                                    onChanged: ((value) {
                                      searchString = value;
                                    }),
                                    onSubmitted: ((value) {
                                      _assetBloc.add(FetchAsset(
                                          search: value, limit: limit));
                                      setState(() {
                                        search = !search;
                                      });
                                    }),
                                  )),
                              ElevatedButton(
                                  child: Text('Search'),
                                  onPressed: () {
                                    _assetBloc.add(FetchAsset(
                                        search: searchString, limit: limit));
                                  })
                            ])
                          : Column(children: [
                              Row(children: <Widget>[
                                Expanded(
                                    child: Text("Name[ID]",
                                        textAlign: TextAlign.center)),
                                if (!ResponsiveWrapper.of(context)
                                    .isSmallerThan(TABLET))
                                  Expanded(
                                      child: Text("Status",
                                          textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text("Product",
                                        textAlign: TextAlign.center)),
                              ]),
                              Divider(color: Colors.black),
                            ]),
                      trailing: Text(' '));
                if (index == 1 && assets.isEmpty)
                  return Center(
                      heightFactor: 20,
                      child: Text("no records found!",
                          textAlign: TextAlign.center));
                index -= 1;
                return index >= assets.length
                    ? BottomLoader()
                    : Dismissible(
                        key: Key(assets[index].assetId!),
                        direction: DismissDirection.startToEnd,
                        child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(assets[index].assetName != null
                                  ? "${assets[index].assetName![0]}"
                                  : "?"),
                            ),
                            title: Row(
                              children: <Widget>[
                                Expanded(
                                    child: Text("${assets[index].assetName}"
                                        "[${assets[index].assetId}]")),
                                if (!ResponsiveWrapper.of(context)
                                    .isSmallerThan(TABLET))
                                  Expanded(
                                      child: Text("${assets[index].statusId}",
                                          textAlign: TextAlign.center)),
                                Expanded(
                                    child: Text("${assets[index].productName}",
                                        textAlign: TextAlign.center)),
                              ],
                            ),
                            onTap: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AssetDialog(
                                        formArguments: FormArguments(
                                            object: assets[index]));
                                  });
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.delete_forever),
                              onPressed: () {
                                _assetBloc.add(DeleteAsset(assets[index]));
                              },
                            )));
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        });
      }
      return Container(child: Center(child: Text("Not Authorized!")));
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
    if (maxScroll - currentScroll <= _scrollThreshold) {
      _assetBloc.add(FetchAsset(limit: limit, search: searchString));
    }
  }
}
