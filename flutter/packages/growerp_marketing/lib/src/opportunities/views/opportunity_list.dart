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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:flutter/gestures.dart';
import '../../l10n/generated/marketing_localizations.dart';
import '../bloc/opportunity_bloc.dart';
import '../widgets/widgets.dart';
import 'views.dart';

class OpportunityList extends StatefulWidget {
  const OpportunityList({super.key});

  @override
  OpportunitiesState createState() => OpportunitiesState();
}

class OpportunitiesState extends State<OpportunityList> {
  final _scrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  late OpportunityBloc _opportunityBloc;
  late List<Opportunity> opportunities;
  late double bottom;
  double? right;
  late MarketingLocalizations localizations;

  @override
  void initState() {
    super.initState();
    _opportunityBloc = context.read<OpportunityBloc>()
      ..add(const OpportunityFetch(refresh: true, limit: 15));
    _scrollController.addListener(_onScroll);
    bottom = 50;
  }

  @override
  Widget build(BuildContext context) {
    localizations = MarketingLocalizations.of(context)!;
    right = right ?? (isAPhone(context) ? 20 : 50);
    return BlocConsumer<OpportunityBloc, OpportunityState>(
      listener: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == OpportunityStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case OpportunityStatus.failure:
            return Center(
                child: Text(localizations.fetchError(state.message!)));
          case OpportunityStatus.success:
            opportunities = state.opportunities;

            Widget tableView() {
              if (opportunities.isEmpty) {
                return Center(
                    heightFactor: 20,
                    child: Text(localizations.noOpportunities,
                        style: const TextStyle(fontSize: 20.0)));
              }
              // get table data formatted for tableView
              var (
                List<List<TableViewCell>> tableViewCells,
                List<double> fieldWidths,
                double? rowHeight
              ) = get2dTableData<Opportunity>(getTableData,
                  bloc: _opportunityBloc,
                  classificationId: 'AppAdmin',
                  context: context,
                  items: opportunities);
              return TableView.builder(
                diagonalDragBehavior: DiagonalDragBehavior.free,
                verticalDetails:
                    ScrollableDetails.vertical(controller: _scrollController),
                horizontalDetails: ScrollableDetails.horizontal(
                    controller: _horizontalScrollController),
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
                                              return index >
                                                      state.opportunities.length
                                                  ? const BottomLoader()
                                                  : Dismissible(
                                                      key: const Key(
                                                          'opportunityItem'),
                                                      direction:
                                                          DismissDirection
                                                              .startToEnd,
                                                      child: BlocProvider.value(
                                                          value:
                                                              _opportunityBloc,
                                                          child:
                                                              OpportunityDialog(
                                                                  opportunities[
                                                                      index -
                                                                          1])));
                                            }))
                          }),
                pinnedRowCount: 1,
              );
            }
            return Stack(
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
                            key: const Key("search"),
                            heroTag: "btn1",
                            onPressed: () async {
                              // find findoc id to show
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    // search separate from finDocBloc
                                    return BlocProvider.value(
                                        value: _opportunityBloc,
                                        child: const SearchOpportunityList());
                                  }).then((value) async => value != null &&
                                      context.mounted
                                  ?
                                  // show detail page
                                  await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BlocProvider.value(
                                            value: _opportunityBloc,
                                            child: OpportunityDialog(value));
                                      })
                                  : const SizedBox.shrink());
                            },
                            child: const Icon(Icons.search)),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                            key: const Key("addNew"),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      BlocProvider.value(
                                          value: _opportunityBloc,
                                          child: OpportunityDialog(
                                              Opportunity())));
                            },
                            tooltip: localizations.addNew,
                            child: const Icon(Icons.add)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          default:
            return const Center(child: LoadingIndicator());
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
    if (_isBottom) _opportunityBloc.add(const OpportunityFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
