/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

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
  late OrderAccountingLocalizations _localizations;

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
    _localizations = OrderAccountingLocalizations.of(context)!;
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
            translateLedgerBlocMessage(state.message, _localizations),
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        if (state.status == LedgerStatus.failure) {
          return FatalErrorForm(message: _localizations.getLedgerTreeFail);
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
                    child: Text(_localizations.expandAll),
                    onPressed: () => setState(() {
                      _controller!.expandAll();
                      expanded = !expanded;
                    }),
                  ),
                const SizedBox(width: 10),
                if (expanded)
                  OutlinedButton(
                    child: Text(_localizations.collapseAll),
                    onPressed: () => setState(() {
                      _controller!.collapseAll();
                      expanded = !expanded;
                    }),
                  ),
                OutlinedButton(
                  child: Text(_localizations.recalculate),
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
                  child: Text(_localizations.glAccountIdAndName),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    _localizations.thisAccount,
                    textAlign: TextAlign.right,
                  ),
                ),
                if (isLargerThanPhone(context))
                  SizedBox(
                    width: 100,
                    child: Text(
                      _localizations.totalTree,
                      textAlign: TextAlign.right,
                    ),
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
