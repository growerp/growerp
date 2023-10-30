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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../asset.dart';

class AssetListForm extends StatelessWidget {
  const AssetListForm({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<AssetBloc>(
        create: (context) =>
            AssetBloc(context.read<RestClient>(), context.read<String>()),
        child: const AssetList(),
      );
}

class AssetList extends StatefulWidget {
  const AssetList({super.key});
  @override
  AssetListState createState() => AssetListState();
}

class AssetListState extends State<AssetList> {
  final _scrollController = ScrollController();
  late AssetBloc _assetBloc;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'Asset';
    _scrollController.addListener(_onScroll);
    _assetBloc = context.read<AssetBloc>();
    _assetBloc.add(const AssetFetch());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetBloc, AssetState>(
        listenWhen: (previous, current) =>
            previous.status == AssetStatus.loading,
        listener: (context, state) {
          print("=====asset list status: ${state.status}");
          if (state.status == AssetStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
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
                      heroTag: "assetNew",
                      key: const Key("addNew"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return BlocProvider.value(
                                  value: _assetBloc,
                                  child: AssetDialog(Asset()));
                            });
                      },
                      tooltip: CoreLocalizations.of(context)!.addNew,
                      child: const Icon(Icons.add)),
                  body: Column(children: [
                    const AssetListHeader(),
                    Expanded(
                        child: RefreshIndicator(
                            onRefresh: (() async => _assetBloc
                                .add(const AssetFetch(refresh: true))),
                            child: ListView.builder(
                                key: const Key('listView'),
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: state.hasReachedMax
                                    ? state.assets.length + 1
                                    : state.assets.length + 2,
                                controller: _scrollController,
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == 0) {
                                    return Visibility(
                                        visible: state.assets.isEmpty,
                                        child: Center(
                                            heightFactor: 20,
                                            child: Text(
                                                "no ${entityName}s found!",
                                                key: const Key('empty'),
                                                textAlign: TextAlign.center)));
                                  }
                                  index--;
                                  return index >= state.assets.length
                                      ? const BottomLoader()
                                      : Dismissible(
                                          key: const Key('assetItem'),
                                          direction:
                                              DismissDirection.startToEnd,
                                          child: AssetListItem(
                                              asset: state.assets[index],
                                              index: index));
                                })))
                  ]));
            default:
              return const Center(child: CircularProgressIndicator());
          }
        });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<AssetBloc>().add(const AssetFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
