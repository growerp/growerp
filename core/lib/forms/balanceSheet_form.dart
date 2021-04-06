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

import 'package:core/blocs/@blocs.dart';
import 'package:core/forms/@forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:core/helper_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';

class BalanceSheetForm extends StatefulWidget {
  @override
  _BalanceSheetFormState createState() => _BalanceSheetFormState();
}

class _BalanceSheetFormState extends State<BalanceSheetForm> {
  TreeController? _controller;
  Iterable<TreeNode?> balanceSheetTree = [];

  @override
  void initState() {
    super.initState();
    _controller = TreeController(allNodesExpanded: false);
    BlocProvider.of<AccntBloc>(context)..add(FetchBalanceSheet());
  }

  @override
  Widget build(BuildContext context) {
    Iterable<TreeNode?> convert(BalanceSheet bs) {
      TreeNode? getTreeNode(ClassInfo? classInfo) {
        if (classInfo == null) return null;
        TreeNode result = TreeNode(
          key: ValueKey(classInfo.id),
          content: Row(children: [
            Text(classInfo.description!),
            Text(classInfo.periodsAmount[0].toString())
          ]),
          children: classInfo.children.map((x) => getTreeNode(x)).toList() as List<TreeNode>?,
        );
        return result;
      }

      List<TreeNode?> nodes = [];
      if (bs.asset != null) nodes.add(getTreeNode(bs.asset));
      if (bs.liability != null) nodes.add(getTreeNode(bs.liability));
      if (bs.equity != null) nodes.add(getTreeNode(bs.equity));
      if (bs.distribution != null) nodes.add(getTreeNode(bs.distribution));
      Iterable<TreeNode?> iterable = nodes;
      return iterable;
    }

    return BlocConsumer<AccntBloc, AccntState>(listener: (context, state) {
      if (state is AccntProblem)
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
    }, builder: (context, state) {
      if (state is AccntProblem)
        return FatalErrorForm("Could not load balance sheet!");
      if (state is AccntSuccess) balanceSheetTree = convert(state.balanceSheet!);
      return ListView(
        children: <Widget>[
          ElevatedButton(
            child: Text("Expand All"),
            onPressed: () => setState(() {
              _controller!.expandAll();
            }),
          ),
          ElevatedButton(
            child: Text("Collapse All"),
            onPressed: () => setState(() {
              _controller!.collapseAll();
            }),
          ),
          buildTree(),
        ],
      );
    });
  }

  Widget buildTree() {
    return TreeView(
      treeController: _controller,
      nodes: balanceSheetTree as List<TreeNode>,
      indent: 10,
    );
  }
}
