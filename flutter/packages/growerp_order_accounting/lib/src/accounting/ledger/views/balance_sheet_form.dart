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
import 'package:decimal/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting.dart';

class BalanceSheetForm extends StatelessWidget {
  // ignore: use_super_parameters
  const BalanceSheetForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LedgerBloc(context.read<RestClient>()),
      child: const BalanceSheetListForm(),
    );
  }
}

class BalanceSheetListForm extends StatefulWidget {
  const BalanceSheetListForm({super.key});

  @override
  BalanceSheetFormState createState() => BalanceSheetFormState();
}

class BalanceSheetFormState extends State<BalanceSheetListForm> {
  final TextEditingController _periodSearchBoxController =
      TextEditingController();
  NumberFormat formatter = NumberFormat("00");
  TreeController? _controller;
  Iterable<TreeNode> _nodes = [];
  late int level;
  late LedgerBloc _ledgerBloc;
  late bool expanded;
  var assets = Decimal.parse('0');
  var equity = Decimal.parse('0');
  var distribution = Decimal.parse('0');
  var liability = Decimal.parse('0');
  var income = Decimal.parse('0');
  late TimePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _controller = TreeController(allNodesExpanded: false);
    _ledgerBloc = context.read<LedgerBloc>();
    _selectedPeriod =
        TimePeriod(periodName: 'Y${DateTime.now().year}', periodType: 'Y');
    _ledgerBloc.add(
        LedgerFetch(ReportType.sheet, periodName: _selectedPeriod.periodName));
    level = 0;
    expanded = false;
    _controller!.expandNode(const Key('ASSETS'));
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    //convert balanceSheetDetail list into TreeNodes
    Iterable<TreeNode> convert(List<GlAccount> glAccounts) {
      // convert single leaf/balanceSheetDetail
      TreeNode getTreeNode(GlAccount glAccount) {
        // recursive function
        if (glAccount.accountCode != null &&
            glAccount.accountCode != 'INCOME') {
          final result = TreeNode(
            key: ValueKey(glAccount.accountCode),
            content: Row(children: [
              SizedBox(
                  width: (isPhone ? 210 : 400) - (level * 10),
                  child: Text(
                      "${int.tryParse(glAccount.accountCode!.substring(0, 2)) == null ? '' : glAccount.accountCode} ${glAccount.accountName}")),
              SizedBox(
                  width: 100,
                  child: Text(
                      Constant.numberFormat.format(DecimalIntl(Decimal.parse(
                          glAccount.postedBalance != null
                              ? glAccount.postedBalance.toString()
                              : '0'))),
                      textAlign: TextAlign.right)),
            ]),
            children: glAccount.children.map(getTreeNode).toList(),
          );
          return result;
        } else {
          return TreeNode();
        }
      }

      // main: do the actual conversion
      final treeNodes = <TreeNode>[];
      for (final element in glAccounts) {
        if (element.accountCode == 'EQUITY') {
          equity = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'DISTRIBUTION') {
          distribution = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'ASSET') {
          assets = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'LIABILITY') {
          liability = element.postedBalance ?? Decimal.zero;
        }
        if (element.accountCode == 'INCOME') {
          income = element.postedBalance ?? Decimal.zero;
        }
        treeNodes.add(getTreeNode(element));
      }
      final Iterable<TreeNode> iterable = treeNodes;
      return iterable;
    }

    return BlocConsumer<LedgerBloc, LedgerState>(listener: (context, state) {
      if (state.status == LedgerStatus.failure) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.red);
      }
    }, builder: (context, state) {
      switch (state.status) {
        case LedgerStatus.success:
          _selectedPeriod = state.ledgerReport!.period!;
          _nodes = convert(state.ledgerReport!.glAccounts);
          List totals = [
            {"text": "Total Assets", "amount": assets},
            {
              "text": "Total Equity + Distribution",
              "amount": equity + distribution
            },
            {"text": "Total Liability + Equity", "amount": liability + equity},
            {"text": "Total Unbooked net income", "amount": income},
            {
              "text": "Liability + Equity + Unbd. Net Income",
              "amount": liability + equity + income
            },
          ];
          return Scaffold(
              body: RefreshIndicator(
                  onRefresh: (() async => context.read<LedgerBloc>().add(
                      LedgerFetch(ReportType.sheet,
                          periodName: _selectedPeriod.periodName))),
                  child: ListView(children: <Widget>[
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      SizedBox(
                        width: 150,
                        child: DropdownSearch<TimePeriod>(
                          key: const Key('periodDropDown'),
                          selectedItem: _selectedPeriod,
                          popupProps: PopupProps.menu(
                            isFilterOnline: true,
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              autofocus: true,
                              decoration: const InputDecoration(
                                  labelText: 'Time period'),
                              controller: _periodSearchBoxController,
                            ),
                            menuProps: MenuProps(
                                borderRadius: BorderRadius.circular(20.0)),
                            title: popUp(
                              context: context,
                              title: 'Select period',
                              height: 50,
                            ),
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Time period',
                            ),
                          ),
                          itemAsString: (TimePeriod? u) =>
                              " ${u!.periodName}", // invisible char for test
                          onChanged: (TimePeriod? newValue) {
                            setState(() => _selectedPeriod = newValue!);
                            _ledgerBloc.add(LedgerFetch(ReportType.sheet,
                                periodName: newValue!.periodName));
                          },
                          items: state.timePeriods,
                          validator: (value) =>
                              value == null ? 'field required' : null,
                        ),
                      ),
                      if (_selectedPeriod.periodType != 'Y')
                        OutlinedButton(
                            child: const Text('Y'),
                            onPressed: () => _ledgerBloc.add(LedgerFetch(
                                ReportType.sheet,
                                periodName: _selectedPeriod.periodName
                                    .substring(0, 5)))),
                      if (_selectedPeriod.periodType != 'Q')
                        OutlinedButton(
                            child: const Text('Q'),
                            onPressed: () {
                              String currentQuarter = formatter
                                  .format(DateTime.now().month / 4 + 1);
                              _ledgerBloc.add(LedgerFetch(ReportType.sheet,
                                  periodName:
                                      '${_selectedPeriod.periodName.substring(0, 5)}'
                                      'q$currentQuarter'));
                            }),
                      if (_selectedPeriod.periodType != 'M')
                        OutlinedButton(
                            child: const Text('M'),
                            onPressed: () => _ledgerBloc.add(LedgerFetch(
                                ReportType.sheet,
                                periodName:
                                    '${_selectedPeriod.periodName.substring(0, 5)}'
                                    'm${formatter.format(DateTime.now().month)}'))),
                      if (!expanded)
                        OutlinedButton(
                          child: const Text('Exp.'),
                          onPressed: () => setState(() {
                            expanded = !expanded;
                            _controller!.expandAll();
                          }),
                        ),
                      if (expanded)
                        OutlinedButton(
                          child: const Text('Col.'),
                          onPressed: () => setState(() {
                            expanded = !expanded;
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
                          width: 100,
                          child: Text('Posted', textAlign: TextAlign.right)),
                    ]),
                    const Divider(),
                    TreeView(
                        treeController: _controller,
                        nodes: _nodes as List<TreeNode>,
                        indent: 10),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Table(
                          columnWidths: const <int, TableColumnWidth>{
                            0: FixedColumnWidth(250),
                            1: FixedColumnWidth(100)
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: <TableRow>[
                            for (var item in totals)
                              TableRow(children: <Widget>[
                                TableCell(child: Text(item["text"])),
                                TableCell(
                                    child: Text(
                                        Constant.numberFormat.format(
                                            DecimalIntl(item["amount"])),
                                        textAlign: TextAlign.right)),
                              ])
                          ]),
                    )
                  ])));
        case LedgerStatus.failure:
          return const FatalErrorForm(message: 'failed to get balance sheet');
        default:
          return const LoadingIndicator();
      }
    });
  }
}
