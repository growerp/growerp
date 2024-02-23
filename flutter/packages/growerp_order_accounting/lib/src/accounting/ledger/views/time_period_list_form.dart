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

import '../../accounting.dart';

class TimePeriodListForm extends StatelessWidget {
  const TimePeriodListForm({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<LedgerBloc>(
        create: (context) => LedgerBloc(context.read<RestClient>()),
        child: const TimePeriodList(),
      );
}

class TimePeriodList extends StatefulWidget {
  const TimePeriodList({super.key});
  @override
  TimePeriodListState createState() => TimePeriodListState();
}

class TimePeriodListState extends State<TimePeriodList> {
  final _scrollController = ScrollController();
  late LedgerBloc _ledgerBloc;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'TimePeriod';
    _ledgerBloc = context.read<LedgerBloc>();
    _ledgerBloc.add(LedgerTimePeriods());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LedgerBloc, LedgerState>(
        listenWhen: (previous, current) =>
            previous.status == LedgerStatus.loading,
        listener: (context, state) {
          if (state.status == LedgerStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
          if (state.status == LedgerStatus.success) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case LedgerStatus.failure:
              return Center(
                  child: Text('failed to fetch timePeriods: ${state.message}'));
            case LedgerStatus.success:
              return Scaffold(
                  floatingActionButton: FloatingActionButton(
                      heroTag: "timePeriodNew",
                      key: const Key("addNew"),
                      onPressed: () async {},
                      tooltip: CoreLocalizations.of(context)!.addNew,
                      child: const Icon(Icons.add)),
                  body: Column(children: [
                    const TimePeriodListHeader(),
                    Expanded(
                        child: RefreshIndicator(
                            onRefresh: (() async =>
                                _ledgerBloc.add(LedgerTimePeriods())),
                            child: ListView.builder(
                                key: const Key('listView'),
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: state.timePeriods.length,
                                controller: _scrollController,
                                itemBuilder: (BuildContext context, int index) {
                                  if (state.timePeriods.isEmpty) {
                                    return Visibility(
                                        visible: state.timePeriods.isEmpty,
                                        child: Center(
                                            heightFactor: 20,
                                            child: Text(
                                                "no ${entityName}s found!",
                                                key: const Key('empty'),
                                                textAlign: TextAlign.center)));
                                  } else {
                                    return TimePeriodListItem(
                                        timePeriod: state.timePeriods[index],
                                        index: index);
                                  }
                                })))
                  ]));
            default:
              return const Center(child: CircularProgressIndicator());
          }
        });
  }
}
