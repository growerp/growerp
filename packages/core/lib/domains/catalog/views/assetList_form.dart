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
import 'package:global_configuration/global_configuration.dart';
import '../../domains.dart';

import '../../../api_repository.dart';
import '../../common/functions/helper_functions.dart';

class AssetListForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          AssetBloc(context.read<APIRepository>())..add(AssetFetch()),
      child: AssetList(),
    );
  }
}

class AssetList extends StatefulWidget {
  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetList> {
  final _scrollController = ScrollController();
  late AssetBloc _assetBloc;
  Authenticate authenticate = Authenticate();
  int limit = 20;
  late bool search;
  String? searchString;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'Asset';
    _assetBloc = context.read<AssetBloc>();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetBloc, AssetState>(
      listener: (context, state) {
        if (state.status == AssetStatus.failure)
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        if (state.status == AssetStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case AssetStatus.failure:
            return Center(
                child: Text('failed to fetch assets: ${state.message}'));
          case AssetStatus.success:
            return Scaffold(
                floatingActionButton: FloatingActionButton(
                    key: Key("addNew"),
                    onPressed: () async {
                      await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider.value(
                                value: _assetBloc, child: AssetDialog(Asset()));
                          });
                    },
                    tooltip: 'Add New',
                    child: Icon(Icons.add)),
                body: RefreshIndicator(
                    onRefresh: (() async =>
                        _assetBloc.add(AssetFetch(refresh: true))),
                    child: ListView.builder(
                      key: Key('listView'),
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: state.hasReachedMax
                          ? state.assets.length + 1
                          : state.assets.length + 2,
                      controller: _scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0)
                          return Column(children: [
                            AssetListHeader(),
                            Visibility(
                                visible: state.assets.isEmpty,
                                child: Center(
                                    heightFactor: 20,
                                    child: Text("no ${entityName}s found!",
                                        key: Key('empty'),
                                        textAlign: TextAlign.center)))
                          ]);
                        index--;
                        return index >= state.assets.length
                            ? BottomLoader()
                            : Dismissible(
                                key: Key('assetItem'),
                                direction: DismissDirection.startToEnd,
                                child: AssetListItem(
                                    asset: state.assets[index], index: index));
                      },
                    )));
          default:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<AssetBloc>().add(AssetFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
