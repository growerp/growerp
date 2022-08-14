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

import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:core/domains/domains.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductForm extends StatefulWidget {
  final Product? product;

  const ProductForm(this.product);
  @override
  _ProductEcomFormState createState() => _ProductEcomFormState(product);
}

class _ProductEcomFormState extends State<ProductForm> {
  final Product? product;
  Decimal quantity = Decimal.parse('1');
  FinDocItem? orderItem;
  Map<String, dynamic>? args;
  bool isFavorite = false;

  _ProductEcomFormState(this.product);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Product detail'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(bottom: 50),
          child: Stack(
            children: <Widget>[
              buildBodyColumn(),
              Align(
                alignment: Alignment.bottomCenter,
                child: buildActionsContainer(),
              ),
            ],
          ),
        ));
  }

  Widget buildBodyColumn() {
    Size size = MediaQuery.of(context).size;
    double screenWidth = size.width;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: screenWidth,
            height: 70,
          ),
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.25),
            child: Hero(
              tag: product!.productId,
              child: product!.image != null
                  ? Image.memory(
                      product!.image!,
                      height: 200,
                      width: screenWidth * 0.5,
                    )
                  : Image.asset('assets/images/default.png'),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Text(
              product!.productName!,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 26),
            ),
            width: screenWidth * 0.9,
          ),
/*          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              '${product.weight}g',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
*/
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                buildAmountButton(),
                Text(
                  (product!.price ?? Decimal.parse('0') * quantity).toString(),
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 26),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 10),
            child: Text(
              'About the product',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "${product!.description}",
              maxLines: 3,
              overflow: TextOverflow.fade,
              style: TextStyle(fontSize: 18),
            ),
          ),
          SizedBox(height: 75)
        ],
      ),
    );
  }

  Widget buildAmountButton() {
    return Container(
      width: 100,
      height: 35,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey, width: 1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            child: Icon(Icons.remove),
            onTap: () {
              setState(() {
                if (quantity > Decimal.parse('1'))
                  quantity -= Decimal.parse('1');
              });
            },
            onLongPressStart: (_) {
              setState(() {
                quantity = Decimal.parse('1');
              });
            },
          ),
          Text(quantity.toString()),
          GestureDetector(
            child: Icon(Icons.add),
            onTap: () {
              setState(() {
                if (quantity < Decimal.parse('25'))
                  quantity += Decimal.parse('1');
              });
            },
            onLongPressStart: (_) {
              setState(() {
                quantity = Decimal.parse('25');
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildActionsContainer() {
    return BlocBuilder<SalesCartBloc, CartState>(builder: (context, state) {
      if (state.status == CartStatus.inProcess) {
        Size size = MediaQuery.of(context).size;
        double screenWidth = size.width;
        return Container(
          color: Color(0xfffafafa),
          width: screenWidth,
          height: 80,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 1)),
                  child: Center(
                      child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          })),
                ),
                MaterialButton(
                  onPressed: () => {
                    HelperFunctions.showMessage(
                        context,
                        'Added $quantity x ${product!.productName}',
                        Colors.green),
                    orderItem = FinDocItem(
                        productId: product!.productId,
                        quantity: quantity,
                        price: product!.price,
                        description: product!.productName),
                    BlocProvider.of<SalesCartBloc>(context).add(
                        CartAdd(finDoc: state.finDoc, newItem: orderItem!)),
                  },
                  splashColor: Theme.of(context).primaryColor,
                  color: Colors.amber[600],
                  elevation: 0,
                  child: Text(
                    'Add to cart',
                  ),
                  height: 50,
                  minWidth: screenWidth - 150,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(45)),
                )
              ],
            ),
          ),
        );
      }
      return Text('Something went wrong!');
    });
  }
}
