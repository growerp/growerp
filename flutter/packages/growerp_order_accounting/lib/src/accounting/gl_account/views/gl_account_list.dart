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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_models/growerp_models.dart';
import '../../accounting.dart';

class GlAccountList extends StatefulWidget {
  const GlAccountList({super.key});

  @override
  GlAccountsState createState() => GlAccountsState();
}

class GlAccountsState extends State<GlAccountList> {
  final ScrollController _scrollController = ScrollController();
  late GlAccountBloc _glAccountBloc;
  late bool trialBalance;
  late int limit;
  late double top;
  double? left;

  @override
  void initState() {
    super.initState();
    trialBalance = false;
    limit = 20;
    _scrollController.addListener(_onScroll);
    _glAccountBloc = context.read<GlAccountBloc>()
      ..add(GlAccountFetch(refresh: true, limit: limit));
    top = 400;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    left = left ?? (isAPhone(context) ? 320 : width - 500);
    limit = (MediaQuery.of(context).size.height / 100).round();
    return BlocConsumer<GlAccountBloc, GlAccountState>(
        listener: (context, state) {
      if (state.status == GlAccountStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
      if (state.status == GlAccountStatus.success) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
      }
    }, builder: (context, state) {
      switch (state.status) {
        case GlAccountStatus.failure:
          return Center(
              child: Text('failed to fetch glAccounts: ${state.message}'));
        case GlAccountStatus.success:
          return Stack(
            children: [
              Column(children: [
                const GlAccountListHeader(),
                Expanded(
                    child: RefreshIndicator(
                        onRefresh: (() async => _glAccountBloc.add(
                            GlAccountFetch(
                                refresh: true,
                                limit: limit,
                                trialBalance: trialBalance))),
                        child: ListView.builder(
                            key: const Key('listView'),
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.hasReachedMax
                                ? state.glAccounts.length + 1
                                : state.glAccounts.length + 2,
                            controller: _scrollController,
                            itemBuilder: (BuildContext context, int index) {
                              if (index == 0) {
                                return Visibility(
                                    visible: state.glAccounts.isEmpty,
                                    child: const Center(
                                        heightFactor: 20,
                                        child: Text(
                                            'No active glAccounts found',
                                            key: Key('empty'),
                                            textAlign: TextAlign.center)));
                              }
                              index--;
                              return index >= state.glAccounts.length
                                  ? const BottomLoader()
                                  : Dismissible(
                                      key: const Key('glAccountItem'),
                                      direction: DismissDirection.startToEnd,
                                      child: GlAccountListItem(
                                          glAccount: state.glAccounts[index],
                                          index: index));
                            })))
              ]),
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      left = left! + details.delta.dx;
                      top += details.delta.dy;
                    });
                  },
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FloatingActionButton(
                            heroTag: 'productFiles',
                            key: const Key("upDownload"),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                        value: _glAccountBloc,
                                        child: const GlAccountFilesDialog());
                                  });
                            },
                            tooltip: 'products up/download',
                            child: const Icon(Icons.file_copy)),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                            heroTag: "trialBalance",
                            key: const Key("tb"),
                            onPressed: () {
                              bool refresh = false;
                              if (trialBalance == false) {
                                trialBalance = true;
                                limit = 999;
                              } else {
                                trialBalance = false;
                                refresh = true;
                                limit = 20;
                              }
                              _glAccountBloc.add(GlAccountFetch(
                                  trialBalance: trialBalance,
                                  limit: limit,
                                  refresh: refresh));
                            },
                            tooltip: 'Trial Balance',
                            child: Text(
                              "TB",
                              style: trialBalance
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough)
                                  : null,
                            )),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                            heroTag: "addNew",
                            key: const Key("addNew"),
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BlocProvider.value(
                                        value: _glAccountBloc,
                                        child: GlAccountDialog(GlAccount()));
                                  });
                            },
                            tooltip: CoreLocalizations.of(context)!.addNew,
                            child: const Icon(Icons.add))
                      ]),
                ),
              ),
            ],
          );
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
    if (_isBottom) {
      _glAccountBloc
          .add(GlAccountFetch(trialBalance: trialBalance, limit: limit));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
