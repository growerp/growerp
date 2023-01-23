/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:growerp_core/growerp_core.dart';
import '../../api_repository.dart';
import '../blocs/blocs.dart';

class LedgerTreeForm extends StatelessWidget {
  const LedgerTreeForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GlAccountBloc(FinDocAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!))
        ..add(const GlAccountFetch()),
      child: const LedgerTreeListForm(),
    );
  }
}

class LedgerTreeListForm extends StatefulWidget {
  const LedgerTreeListForm({Key? key}) : super(key: key);

  @override
  LedgerTreeFormState createState() => LedgerTreeFormState();
}

class LedgerTreeFormState extends State<LedgerTreeListForm> {
  TreeController? _controller;
  Iterable<TreeNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _controller = TreeController(allNodesExpanded: false);
    context.read<GlAccountBloc>().add(const GlAccountFetch());
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    //convert glAccount list into TreeNodes
    Iterable<TreeNode> convert(List<GlAccount> glAccounts) {
      // convert single leaf/glAccount
      TreeNode getTreeNode(GlAccount glAccount) {
        // recursive function
        final result = TreeNode(
          key: ValueKey(glAccount.id),
          content: Row(children: [
            SizedBox(
                width: (isPhone ? 210 : 400) - (glAccount.l!.toDouble() * 10),
                child: Text('${glAccount.id} ${glAccount.accountName} ')),
            SizedBox(
                width: 100,
                child: Text(
                    NumberFormat.simpleCurrency()
                        .format(glAccount.postedBalance),
                    textAlign: TextAlign.right)),
            SizedBox(
                width: 100,
                child: Text(
                    NumberFormat.simpleCurrency().format(glAccount.rollUp),
                    textAlign: TextAlign.right))
          ]),
          children: glAccount.children.map(getTreeNode).toList(),
        );
        return result;
      }

      // main: do the actual conversion
      final treeNodes = <TreeNode>[];
      for (final element in glAccounts) {
        treeNodes.add(getTreeNode(element));
      }
      final Iterable<TreeNode> iterable = treeNodes;
      return iterable;
    }

    return BlocConsumer<GlAccountBloc, GlAccountState>(
        listener: (context, state) {
      if (state.status == GlAccountStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      if (state.status == GlAccountStatus.failure) {
        return const FatalErrorForm('Could not load Ledger tree!');
      }
      if (state.status == GlAccountStatus.success) {
        _nodes = convert(state.glAccounts);
      }
      return ListView(
        children: <Widget>[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton(
              child: const Text('Expand All'),
              onPressed: () => setState(() {
                _controller!.expandAll();
              }),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              child: const Text('Collapse All'),
              onPressed: () => setState(() {
                _controller!.collapseAll();
              }),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const SizedBox(width: 20),
            SizedBox(
                width: isPhone ? 220 : 410,
                child: const Text('Gl Account ID  GL Account Name')),
            const SizedBox(
                width: 100, child: Text('Posted', textAlign: TextAlign.right)),
            const SizedBox(
                width: 100, child: Text('Roll Up', textAlign: TextAlign.right))
          ]),
          const Divider(color: Colors.black),
          TreeView(
              treeController: _controller,
              nodes: _nodes as List<TreeNode>,
              indent: 10)
        ],
      );
    });
  }
}
