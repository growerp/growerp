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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:models/models.dart';
import '../blocs/@blocs.dart';
import '../helper_functions.dart';
import '../routing_constants.dart';
import '../widgets/@widgets.dart';

class OrdersForm extends StatelessWidget {
  final FormArguments formArguments;
  OrdersForm(this.formArguments);
  @override
  Widget build(BuildContext context) {
    var a = (formArguments) =>
        (OrdersFormHeader(formArguments.message, formArguments.object));
    return ShowNavigationRail(a(formArguments), 5, formArguments.object);
  }
}

class OrdersFormHeader extends StatefulWidget {
  final String message;
  final Authenticate authenticate;
  const OrdersFormHeader([this.message, this.authenticate]);
  @override
  _OrdersFormStateHeader createState() =>
      _OrdersFormStateHeader(message, authenticate);
}

class _OrdersFormStateHeader extends State<OrdersFormHeader> {
  final String message;
  final Authenticate authenticate;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _OrdersFormStateHeader([this.message, this.authenticate]) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }
  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = this.authenticate;
    List<Order> orders;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      return ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Scaffold(
              appBar: AppBar(
                  title:
                      companyLogo(context, authenticate, 'Company Orders List'),
                  automaticallyImplyLeading:
                      ResponsiveWrapper.of(context).isSmallerThan(TABLET)),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, OrderRoute,
                      arguments: FormArguments('Enter a new Order...'));
                },
                tooltip: 'Add new order',
                child: Icon(Icons.add),
              ),
              drawer: myDrawer(context, authenticate),
              body: BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is AuthProblem)
                      HelperFunctions.showMessage(
                          context, '${state.errorMessage}', Colors.red);
                  },
                  child: BlocConsumer<OrderBloc, OrderState>(
                      listener: (context, state) {
                    if (state is OrderProblem)
                      HelperFunctions.showMessage(
                          context, '${state.errorMessage}', Colors.red);
                    if (state is OrderLoading)
                      HelperFunctions.showMessage(
                          context, '${state.message}', Colors.green);
                    if (state is OrderLoaded)
                      HelperFunctions.showMessage(
                          context, '${state.message}', Colors.green);
                  }, builder: (context, state) {
                    if (state is OrderLoading)
                      return Center(child: CircularProgressIndicator());
                    if (state is OrderLoaded) orders = state.orders;
                    return orderList(orders);
                  }))));
    });
  }

  Widget orderList(orders) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          // you could add any widget
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
            ),
            title: Row(
              children: <Widget>[
                Expanded(child: Text("Customer", textAlign: TextAlign.center)),
                Expanded(child: Text("Email", textAlign: TextAlign.center)),
                Expanded(child: Text("Date", textAlign: TextAlign.center)),
                Expanded(child: Text("Total", textAlign: TextAlign.center)),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Expanded(child: Text("Status", textAlign: TextAlign.center)),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Expanded(child: Text("#items", textAlign: TextAlign.center)),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return InkWell(
                onTap: () async {
                  dynamic result = await Navigator.pushNamed(
                      context, OrderRoute,
                      arguments: FormArguments(null, orders[index]));
                  setState(() {
                    if (result is List) orders = result;
                  });
                  HelperFunctions.showMessage(
                      context,
                      'Order ${orders[index].firstName} '
                      '${orders[index].lastName} modified',
                      Colors.green);
                },
                onLongPress: () async {
                  bool result = await confirmDialog(
                      context,
                      "${orders[index].firstName} ${orders[index].lastName}",
                      "Delete this order?");
                  if (result) {
                    BlocProvider.of<OrderBloc>(context)
                        .add(CancelOrder(orders, orders[index].orderId));
                    Navigator.pushNamed(context, OrdersRoute,
                        arguments:
                            FormArguments('Order deleted', authenticate));
                  }
                },
                child: ListTile(
                  //return  ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(orders[index]?.orderStatusId[0]),
                  ),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                          child: Text("${orders[index].lastName}, "
                              "${orders[index].firstName} "
                              "[${orders[index].customerPartyId}]")),
                      Expanded(
                          child: Text("${orders[index].email}",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("${orders[index].placedDate}",
                              textAlign: TextAlign.center)),
                      Expanded(
                          child: Text("${orders[index].grandTotal}",
                              textAlign: TextAlign.center)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                        Expanded(
                            child: Text("${orders[index].orderStatusId}",
                                textAlign: TextAlign.center)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                        Expanded(
                            child: Text("${orders[index].orderItems?.length}",
                                textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              );
            },
            childCount: orders == null ? 0 : orders?.length,
          ),
        ),
      ],
    );
  }
}
