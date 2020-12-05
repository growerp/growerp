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
import 'package:core/blocs/@blocs.dart';
import 'package:models/models.dart';
import 'package:core/routing_constants.dart';
import 'package:core/helper_functions.dart';

class CartForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () => Navigator.pushNamed(context, HomeRoute)),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _CartList(),
              ),
            ),
            Divider(height: 4, color: Colors.black),
            _CartTotal()
          ],
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartLoading) return CircularProgressIndicator();
        if (state is CartLoaded) {
          return DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Total')),
            ],
            rows: state.order.orderItems
                .map((orderItem) => DataRow(cells: [
                      DataCell(Text(orderItem.description)),
                      DataCell(Text(orderItem.quantity.toString())),
                      DataCell(Text(orderItem.price.toString())),
                      DataCell(Text(
                          (orderItem.price * orderItem.quantity).toString())),
                    ]))
                .toList(),
          );
        }
        if (state is CartProblem) {
          return Center(
            child: Text(state.errorMessage),
          );
        }
        return Container();
      },
    );
  }
}

class _CartTotal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hugeStyle =
        Theme.of(context).textTheme.headline1.copyWith(fontSize: 48);
    Order order;
    return SizedBox(
        height: 200,
        child: Center(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          BlocListener<CartBloc, CartState>(listener: (context, state) {
            if (state is CartPaid) {
              Navigator.pushNamedAndRemoveUntil(
                  context, HomeRoute, ModalRoute.withName(HomeRoute),
                  arguments: "Order Accepted, id:${state.orderId}");
            }
          }, child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
            return BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
              if (cartState is CartLoading || cartState is CartPaying) {
                return CircularProgressIndicator();
              }
              if (cartState is CartProblem) {
                HelperFunctions.showMessage(
                    context, 'Cart error: $cartState.message}?', Colors.red);
              }
              if (cartState is CartLoaded) {
                order = cartState.order;
                return Row(children: <Widget>[
                  Text((cartState.totalPrice ?? 0.00).toString(),
                      style: hugeStyle),
                  RaisedButton(
                      disabledColor: Colors.white,
                      disabledTextColor: Colors.white,
                      child: Text('BUY', style: hugeStyle),
                      color: Colors.orange,
                      onPressed: order == null || order.orderItems.length == 0
                          ? null
                          : () async {
                              dynamic result;
                              if (state is! AuthAuthenticated) {
                                result = await Navigator.pushNamed(
                                    context, LoginRoute,
                                    arguments: 'Please login/register first?');
                              }
                              if (state is AuthAuthenticated ||
                                  result == true) {
                                HelperFunctions.showMessage(
                                    context, 'Sending order...', Colors.green);
                                BlocProvider.of<CartBloc>(context)
                                    .add(ConfirmCart());
                              }
                            }),
                ]);
              }
              return Container();
            });
          }))
        ])));
  }
}
