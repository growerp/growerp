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
import '../../accounting.dart';

class GlAccountListForm extends StatelessWidget {
  const GlAccountListForm({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (BuildContext context) => GlAccountBloc(AccountingAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!))
        ..add(const GlAccountFetch()),
      child: const GlAccountList());
}

class GlAccountList extends StatefulWidget {
  const GlAccountList({super.key});

  @override
  GlAccountsState createState() => GlAccountsState();
}

class GlAccountsState extends State<GlAccountList> {
  final ScrollController _scrollController = ScrollController();
  late GlAccountBloc _glAccountBloc;

  @override
  void initState() {
    super.initState();
    _glAccountBloc = context.read<GlAccountBloc>();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<GlAccountBloc, GlAccountState>(listener: (context, state) {
        if (state.status == GlAccountStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == GlAccountStatus.success) {
          HelperFunctions.showMessage(
              context, '${state.message}', Colors.green);
        }
      }, builder: (context, state) {
        switch (state.status) {
          case GlAccountStatus.failure:
            return Center(
                child: Text('failed to fetch glAccounts: ${state.message}'));
          case GlAccountStatus.success:
            return Scaffold(
                floatingActionButton: FloatingActionButton(
                    key: const Key("addNew"),
                    onPressed: () async {
                      await showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) => BlocProvider.value(
                              value: _glAccountBloc,
                              child: GlAccountDialog(GlAccount())));
                    },
                    tooltip: 'Add New',
                    child: const Icon(Icons.add)),
                body: Column(children: [
                  const GlAccountListHeader(),
                  Expanded(
                      child: RefreshIndicator(
                          onRefresh: (() async => _glAccountBloc
                              .add(const GlAccountFetch(refresh: true))),
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
                ]));
          default:
            return const Center(child: CircularProgressIndicator());
        }
      });

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _glAccountBloc.add(const GlAccountFetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
