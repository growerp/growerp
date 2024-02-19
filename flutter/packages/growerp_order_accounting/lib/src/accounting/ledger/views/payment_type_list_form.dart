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
import 'package:growerp_order_accounting/src/findoc/findoc.dart';

import '../widgets/widgets.dart';

class PaymentTypeListForm extends StatelessWidget {
  const PaymentTypeListForm(this.sales, {super.key});
  final bool sales;
  @override
  Widget build(BuildContext context) => BlocProvider<FinDocBloc>(
        create: (context) => FinDocBloc(context.read<RestClient>(), sales,
            FinDocType.order, context.read<String>()),
        child: PaymentTypeList(sales),
      );
}

class PaymentTypeList extends StatefulWidget {
  const PaymentTypeList(this.sales, {super.key});
  final bool sales;
  @override
  PaymentTypeListState createState() => PaymentTypeListState();
}

class PaymentTypeListState extends State<PaymentTypeList> {
  final _scrollController = ScrollController();
  late FinDocBloc finDocBloc;
  String classificationId = GlobalConfiguration().getValue("classificationId");
  late String entityName;

  @override
  void initState() {
    super.initState();
    entityName = classificationId == 'AppHotel' ? 'Room' : 'PaymentType';
    finDocBloc = context.read<FinDocBloc>();
    finDocBloc.add(FinDocGetPaymentTypes(widget.sales));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinDocBloc, FinDocState>(
        listenWhen: (previous, current) =>
            previous.status == FinDocStatus.loading,
        listener: (context, state) {
          if (state.status == FinDocStatus.failure) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.red);
          }
          if (state.status == FinDocStatus.success) {
            HelperFunctions.showMessage(
                context, '${state.message}', Colors.green);
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case FinDocStatus.failure:
              return Center(
                  child:
                      Text('failed to fetch paymentTypes: ${state.message}'));
            case FinDocStatus.success:
              return Scaffold(
                  floatingActionButton: FloatingActionButton(
                      heroTag: "paymentTypeNew",
                      key: const Key("addNew"),
                      onPressed: () async {},
                      tooltip: CoreLocalizations.of(context)!.addNew,
                      child: const Icon(Icons.add)),
                  body: Column(children: [
                    const PaymentTypeListHeader(),
                    Expanded(
                        child: RefreshIndicator(
                            onRefresh: (() async => finDocBloc
                                .add(FinDocGetPaymentTypes(widget.sales))),
                            child: ListView.builder(
                                key: const Key('listView'),
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: state.paymentTypes.length,
                                controller: _scrollController,
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == 0) {
                                    return Visibility(
                                        visible: state.paymentTypes.isEmpty,
                                        child: Center(
                                            heightFactor: 20,
                                            child: Text(
                                                "no ${entityName}s found!",
                                                key: const Key('empty'),
                                                textAlign: TextAlign.center)));
                                  }
                                  index--;
                                  return index >= state.paymentTypes.length
                                      ? const BottomLoader()
                                      : Dismissible(
                                          key: const Key('paymentTypeItem'),
                                          direction:
                                              DismissDirection.startToEnd,
                                          child: PaymentTypeListItem(
                                              paymentType:
                                                  state.paymentTypes[index],
                                              index: index));
                                })))
                  ]));
            default:
              return const Center(child: CircularProgressIndicator());
          }
        });
  }
}
