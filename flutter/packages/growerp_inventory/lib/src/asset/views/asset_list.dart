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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import '../asset.dart';

class AssetList extends StatefulWidget {
  const AssetList({super.key});
  @override
  AssetListState createState() => AssetListState();
}

class AssetListState extends State<AssetList> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  late AssetBloc _assetBloc;
  late String classificationId;
  late String entityName;

  @override
  void initState() {
    super.initState();
    classificationId = context.read<String>();
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
              Widget tableView() {
                if (state.assets.isEmpty)
                  return Center(
                      heightFactor: 20,
                      child:
                          Text("no assets found", textAlign: TextAlign.center));
                // get table data formatted for tableView
                var (
                  List<List<TableViewCell>> tableViewCells,
                  List<double> fieldWidths,
                  double? rowHeight
                ) = get2dTableData<Asset>(
                  getItemFieldNames,
                  getItemFieldWidth,
                  state.assets,
                  getItemFieldContent,
                  getRowActionButtons: getRowActionButtons,
                  getRowHeight: getRowHeight,
                  context: context,
                  bloc: _assetBloc,
                );
                return TableView.builder(
                  diagonalDragBehavior: DiagonalDragBehavior.free,
                  verticalDetails:
                      ScrollableDetails.vertical(controller: _scrollController),
                  horizontalDetails: ScrollableDetails.horizontal(
                      controller: _horizontalController),
                  cellBuilder: (context, vicinity) =>
                      tableViewCells[vicinity.row][vicinity.column],
                  columnBuilder: (index) => index >= tableViewCells[0].length
                      ? null
                      : TableSpan(
                          padding: padding,
                          backgroundDecoration: getBackGround(context, index),
                          extent: FixedTableSpanExtent(fieldWidths[index]),
                        ),
                  pinnedColumnCount: 1,
                  rowBuilder: (index) => index >= tableViewCells.length
                      ? null
                      : TableSpan(
                          padding: padding,
                          backgroundDecoration: getBackGround(context, index),
                          extent: FixedTableSpanExtent(rowHeight!),
                          recognizerFactories: <Type, GestureRecognizerFactory>{
                              TapGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                          TapGestureRecognizer>(
                                      () => TapGestureRecognizer(),
                                      (TapGestureRecognizer t) =>
                                          t.onTap = () => showDialog(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return index >=
                                                        state.assets.length
                                                    ? const BottomLoader()
                                                    : Dismissible(
                                                        key: const Key(
                                                            'locationItem'),
                                                        direction:
                                                            DismissDirection
                                                                .startToEnd,
                                                        child: BlocProvider.value(
                                                            value: _assetBloc,
                                                            child: AssetDialog(
                                                                state.assets[
                                                                    index -
                                                                        1])));
                                              }))
                            }),
                  pinnedRowCount: 1,
                );
              }

              return Scaffold(
                  floatingActionButton: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                          key: const Key("search"),
                          heroTag: "btn1",
                          onPressed: () async {
                            // find findoc id to show
                            Asset asset = await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  // search separate from finDocBloc
                                  return BlocProvider.value(
                                      value: context
                                          .read<DataFetchBloc<Locations>>(),
                                      child: SearchAssetList());
                                });
                            // show detail page
                            await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocProvider.value(
                                      value: _assetBloc,
                                      child: AssetDialog(asset));
                                });
                          },
                          child: const Icon(Icons.search)),
                      SizedBox(height: 10),
                      FloatingActionButton(
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
                    ],
                  ),
                  body: tableView());
            default:
              return const Center(child: LoadingIndicator());
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
