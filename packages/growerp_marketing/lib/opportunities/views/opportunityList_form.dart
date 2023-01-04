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

import 'package:core/domains/authenticate/blocs/auth_bloc.dart';
import 'package:core/domains/common/widgets/bottom_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/domains/common/functions/functions.dart';

import '../../api_repository.dart';
import '../bloc/opportunity_bloc.dart';
import '../models/opportunity_model.dart';
import '../widgets/opportunityList_header.dart';
import '../widgets/opportunityList_item.dart';
import 'opportunity_dialog.dart';

class OpportunityListForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (BuildContext context) => OpportunityBloc(Marketing_APIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!))
        ..add(OpportunityFetch()),
      child: OpportunityList());
}

class OpportunityList extends StatefulWidget {
  @override
  _OpportunitiesState createState() => _OpportunitiesState();
}

class _OpportunitiesState extends State<OpportunityList> {
  ScrollController _scrollController = ScrollController();
  late OpportunityBloc _opportunityBloc;

  @override
  void initState() {
    super.initState();
    _opportunityBloc = context.read<OpportunityBloc>();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<OpportunityBloc, OpportunityState>(
        listener: (context, state) {
          if (state.status == OpportunityStatus.failure)
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          if (state.status == OpportunityStatus.success) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case OpportunityStatus.failure:
              return Center(
                  child:
                      Text('failed to fetch opportunities: ${state.message}'));
            case OpportunityStatus.success:
              return Scaffold(
                  floatingActionButton: FloatingActionButton(
                      key: Key("addNew"),
                      onPressed: () async {
                        await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) =>
                                BlocProvider.value(
                                    value: _opportunityBloc,
                                    child: OpportunityDialog(Opportunity())));
                      },
                      tooltip: 'Add New',
                      child: Icon(Icons.add)),
                  body: RefreshIndicator(
                      onRefresh: (() async => _opportunityBloc
                          .add(OpportunityFetch(refresh: true))),
                      child: ListView.builder(
                          key: Key('listView'),
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: state.hasReachedMax
                              ? state.opportunities.length + 1
                              : state.opportunities.length + 2,
                          controller: _scrollController,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0)
                              return Column(children: [
                                OpportunityListHeader(),
                                Visibility(
                                    visible: state.opportunities.isEmpty,
                                    child: const Center(
                                        heightFactor: 20,
                                        child: Text(
                                            'No active opportunities found',
                                            key: Key('empty'),
                                            textAlign: TextAlign.center)))
                              ]);
                            index--;
                            return index >= state.opportunities.length
                                ? BottomLoader()
                                : Dismissible(
                                    key: Key('opportunityItem'),
                                    direction: DismissDirection.startToEnd,
                                    child: OpportunityListItem(
                                        opportunity: state.opportunities[index],
                                        index: index));
                          })));
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      );

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _opportunityBloc.add(OpportunityFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
