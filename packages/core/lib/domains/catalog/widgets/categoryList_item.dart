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
import 'package:responsive_framework/responsive_wrapper.dart';
import '../catalog.dart';

class CategoryListItem extends StatelessWidget {
  const CategoryListItem(
      {Key? key, required this.category, required this.index})
      : super(key: key);

  final Category category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final _categoryBloc = context.read<CategoryBloc>();
    return Material(
        child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: category.image != null
                  ? Image.memory(
                      category.image!,
                      height: 100,
                    )
                  : Text(
                      "${category.categoryName.isEmpty ? '?' : category.categoryName[0]}"),
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                    child: Text("${category.categoryName}",
                        key: Key("name$index"))),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Expanded(
                      child: Text("${category.description}",
                          key: Key("description$index"),
                          textAlign: TextAlign.center)),
                Expanded(
                    child: Text("${category.products.length}",
                        key: Key("products$index"),
                        textAlign: TextAlign.center)),
              ],
            ),
            onTap: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                        value: _categoryBloc, child: CategoryDialog(category));
                  });
            },
            trailing: IconButton(
              key: Key('delete$index'),
              icon: Icon(Icons.delete_forever),
              onPressed: () {
                _categoryBloc
                    .add(CategoryDelete(category.copyWith(image: null)));
              },
            )));
  }
}
