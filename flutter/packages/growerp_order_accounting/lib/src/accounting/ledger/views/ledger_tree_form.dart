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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting.dart';

class LedgerTreeForm extends StatelessWidget {
  const LedgerTreeForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LedgerBloc(context.read<RestClient>()),
      child: const LedgerTreeListForm(),
    );
  }
}

class LedgerTreeListForm extends StatefulWidget {
  const LedgerTreeListForm({super.key});

  @override
  LedgerTreeFormState createState() => LedgerTreeFormState();
}

class LedgerTreeFormState extends State<LedgerTreeListForm> {
  TreeController? _controller;
  Iterable<TreeNode> _nodes = [];
  late LedgerBloc _ledgerBloc;
  late bool expanded;
  late String currencyId;

  @override
  void initState() {
    super.initState();
    _controller = TreeController(allNodesExpanded: false);
    _ledgerBloc = context.read<LedgerBloc>();
    _ledgerBloc.add(const LedgerFetch(ReportType.ledger));
    expanded = false;
    currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
  }

  @override
  Widget build(BuildContext context) {
    //convert glAccount list into TreeNodes
    Iterable<TreeNode> convert(List<GlAccount> glAccounts) {
      // convert single leaf/glAccount
      TreeNode getTreeNode(GlAccount glAccount) {
        // recursive function
        final result = TreeNode(
          key: ValueKey(glAccount.accountCode),
          content: Row(
            children: [
              SizedBox(
                width:
                    (isPhone(context) ? 210 : 400) -
                    (glAccount.level!.toDouble() * 10),
                child: Text(
                  '${glAccount.accountCode} ${glAccount.accountName} ',
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  (Decimal.parse(
                    glAccount.postedBalance.toString(),
                  )).currency(currencyId: currencyId),
                  textAlign: TextAlign.right,
                ),
              ),
              if (isLargerThanPhone(context))
                SizedBox(
                  width: 100,
                  child: Text(
                    glAccount.rollUp.currency(currencyId: currencyId),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
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

    return BlocConsumer<LedgerBloc, LedgerState>(
      listener: (context, state) {
        if (state.status == LedgerStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == LedgerStatus.success) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        if (state.status == LedgerStatus.failure) {
          return FatalErrorForm(message: _local.getLedgerTreeFail);
        }
        if (state.status == LedgerStatus.loading) {
          return const LoadingIndicator();
        }
        if (state.status == LedgerStatus.success) {
          _nodes = convert(
            state.ledgerReport != null ? state.ledgerReport!.glAccounts : [],
          );
        }
        return ListView(
          children: <Widget>[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!expanded)
                  OutlinedButton(
                    child: Text(_local.expandAll),
                    onPressed: () => setState(() {
                      _controller!.expandAll();
                      expanded = !expanded;
                    }),
                  ),
                const SizedBox(width: 10),
                if (expanded)
                  OutlinedButton(
                    child: Text(_local.collapseAll),
                    onPressed: () => setState(() {
                      _controller!.collapseAll();
                      expanded = !expanded;
                    }),
                  ),
                OutlinedButton(
                  child: Text(_local.recalculate),
                  onPressed: () => _ledgerBloc.add(LedgerCalculate()),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 20),
                SizedBox(
                  width: isPhone(context) ? 220 : 410,
                  child: Text(_local.glAccountIdAndName),
                ),
                SizedBox(
                  width: 100,
                  child: Text(_local.thisAccount, textAlign: TextAlign.right),
                ),
                if (isLargerThanPhone(context))
                  SizedBox(
                    width: 100,
                    child: Text(_local.totalTree, textAlign: TextAlign.right),
                  ),
              ],
            ),
            const Divider(),
            TreeView(
              treeController: _controller,
              nodes: _nodes as List<TreeNode>,
              indent: 10,
            ),
          ],
        );
      },
    );
  }
}
