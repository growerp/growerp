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
import 'package:growerp_order_accounting/src/findoc/findoc.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../../accounting/accounting.dart';

class PaymentTypeList extends StatefulWidget {
  const PaymentTypeList({super.key});
  @override
  PaymentTypeListState createState() => PaymentTypeListState();
}

class PaymentTypeListState extends State<PaymentTypeList> {
  final _scrollController = ScrollController();
  late FinDocBloc finDocBloc;
  late GlAccountBloc glAccountBloc;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;
  late bool showAll;
  double? top;
  double? left;
  late OrderAccountingLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    showAll = false;
    entityName = classificationId == 'AppHotel' ? 'Room' : 'PaymentType';
    finDocBloc = context.read<FinDocBloc>()..add(const FinDocGetPaymentTypes());
    glAccountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountFetch(refresh: true, limit: 3));
  }

  @override
  Widget build(BuildContext context) {
    _localizations = OrderAccountingLocalizations.of(context)!;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    top = top ?? (isAPhone(context) ? 500 : height - 200);
    left = left ?? (isAPhone(context) ? 280 : width - 300);
    return BlocConsumer<FinDocBloc, FinDocState>(
      listenWhen: (previous, current) =>
          previous.status == FinDocStatus.loading,
      listener: (context, state) {
        if (state.status == FinDocStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == FinDocStatus.success) {
          HelperFunctions.showMessage(
            context,
            '${state.message}',
            Colors.green,
          );
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case FinDocStatus.failure:
            return Center(
              child: Text(
                '${_localizations.fetchPaymentTypesFail} ${state.message}',
              ),
            );
          case FinDocStatus.success:
            var newList = [];
            for (var item in state.paymentTypes) {
              if (showAll) {
                newList.add(item);
              } else {
                if (item.accountCode != '') newList.add(item);
              }
            }

            return Stack(
              children: [
                Column(
                  children: [
                    const PaymentTypeListHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: (() async =>
                            finDocBloc.add(const FinDocGetPaymentTypes())),
                        child: ListView.builder(
                          key: const Key('listView'),
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: newList.length,
                          controller: _scrollController,
                          itemBuilder: (BuildContext context, int index) {
                            return PaymentTypeListItem(
                              paymentType: newList[index],
                              index: index,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        left = left! + details.delta.dx;
                        top = top! + details.delta.dy;
                      });
                    },
                    child: FloatingActionButton.extended(
                      heroTag: 'showAll',
                      key: const Key("switchShow"),
                      onPressed: () {
                        setState(() {
                          showAll = !showAll;
                        });
                      },
                      tooltip: _localizations.showAllUsed,
                      label: showAll
                          ? Text(_localizations.all)
                          : Text(_localizations.onlyUsed),
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
}
