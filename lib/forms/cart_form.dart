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

import 'package:core/forms/login_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:models/@models.dart';
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
              onPressed: () => Navigator.pushNamed(context, '/')),
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
    return BlocBuilder<SalesCartBloc, CartState>(
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
            rows: state.finDoc!.items!
                .map((orderItem) => DataRow(cells: [
                      DataCell(Text(orderItem.description!)),
                      DataCell(Text(orderItem.quantity.toString())),
                      DataCell(Text(orderItem.price.toString())),
                      DataCell(Text(
                          (orderItem.price! * orderItem.quantity!).toString())),
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
    SalesCartBloc _cartBloc =
        BlocProvider.of<SalesCartBloc>(context) as CartBloc;
    SalesOrderBloc _finDocBloc =
        BlocProvider.of<SalesOrderBloc>(context) as FinDocBloc;
    final hugeStyle =
        Theme.of(context).textTheme.headline1!.copyWith(fontSize: 48);
    late FinDoc order;
    return SizedBox(
        height: 200,
        child: Center(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          BlocListener<SalesCartBloc, CartState>(listener: (context, state) {
            if (state is CartPaid) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', ModalRoute.withName('/'),
                  arguments: FormArguments(
                      message: "Order Accepted, id:${state.finDoc!.orderId}"));
            }
          }, child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
            return BlocBuilder<SalesCartBloc, CartState>(
                builder: (context, cartState) {
              if (cartState is CartLoading || cartState is CartPaying) {
                return CircularProgressIndicator();
              }
              if (cartState is CartProblem) {
                HelperFunctions.showMessage(
                    context, 'Cart error: $cartState.message}?', Colors.red);
              }
              if (cartState is CartLoaded) {
                order = cartState.finDoc!;
                return Row(children: <Widget>[
                  Text((cartState.finDoc!.grandTotal ?? 0.00).toString(),
                      style: hugeStyle),
                  ElevatedButton(
                      child: Text('BUY', style: hugeStyle),
                      onPressed: order.items!.length == 0
                          ? null
                          : () async {
                              print("=====buy pressec====state: $state====");
                              if (state is AuthUnauthenticated) {
                                dynamic result = await showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return LoginDialog(
                                          formArguments: FormArguments(
                                              message:
                                                  'Please login/register first?'));
                                    });
                                print("======cartform: login result: $result");
                                if (result is Authenticate) {
                                  print(
                                      "======cartform: login result: $result");
                                  HelperFunctions.showMessage(context,
                                      'Sending order...', Colors.green);
                                  _finDocBloc.add(FetchFinDoc(
                                      customerCompanyPartyId:
                                          result.user!.companyPartyId));
                                  _cartBloc.add(CreateFinDocFromCart(
                                      order.copyWith(otherUser: result.user)));
                                }
                              } else if (state is AuthAuthenticated) {
                                HelperFunctions.showMessage(
                                    context, 'Sending order...', Colors.green);
                                _cartBloc.add(CreateFinDocFromCart(
                                    order.copyWith(
                                        otherUser: state.authenticate.user)));
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
