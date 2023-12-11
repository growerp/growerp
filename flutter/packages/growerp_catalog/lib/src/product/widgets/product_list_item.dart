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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';
import '../product.dart';

class ProductListItem extends StatelessWidget {
  const ProductListItem(
      {super.key, required this.product, required this.index});

  final Product product;
  final int index;

  @override
  Widget build(BuildContext context) {
    String classificationId = GlobalConfiguration().get("classificationId");
    final productBloc = context.read<ProductBloc>();
    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: product.image != null
              ? Image.memory(
                  product.image!,
                  height: 100,
                )
              : Text(product.productName![0]),
        ),
        title: Column(
          children: [
            if (ResponsiveBreakpoints.of(context).equals(MOBILE))
              Text("${product.productName}", key: Key('name$index')),
            Row(
              children: <Widget>[
                if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                  Expanded(
                      child: Text("${product.productName}",
                          key: Key('name$index'))),
                if (!ResponsiveBreakpoints.of(context).isMobile)
                  Expanded(
                      child: Text("${product.description}",
                          key: Key('description$index'),
                          textAlign: TextAlign.center)),
                Expanded(
                    child: Text("${product.price ?? product.listPrice ?? ''}",
                        key: Key('price$index'), textAlign: TextAlign.center)),
                if (classificationId != 'AppHotel')
                  Expanded(
                      child: Text(
                          "${product.categories.isEmpty ? '0' : product.categories.length > 1 ? product.categories.length : product.categories[0].categoryName}",
                          key: Key('categoryName$index'),
                          textAlign: TextAlign.center)),
                Expanded(
                    child: Text(
                        product.assetCount != null
                            ? product.assetCount.toString()
                            : '0',
                        key: Key('assetCount$index'),
                        textAlign: TextAlign.center)),
              ],
            ),
          ],
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) => BlocProvider.value(
                  value: productBloc, child: ProductDialog(product)));
        },
        trailing: IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          onPressed: () {
            productBloc.add(ProductDelete(product.copyWith(image: null)));
          },
        ));
  }
}
