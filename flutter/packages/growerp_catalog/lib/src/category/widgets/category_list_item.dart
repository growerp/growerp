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
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../category.dart';

class CategoryListItem extends StatelessWidget {
  const CategoryListItem(
      {super.key, required this.category, required this.index});

  final Category category;
  final int index;

  @override
  Widget build(BuildContext context) {
    final categoryBloc = context.read<CategoryBloc>();
    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: category.image != null
              ? Image.memory(
                  category.image!,
                  height: 100,
                )
              : Text(category.categoryName.isEmpty
                  ? '?'
                  : category.categoryName[0]),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
                child: Text(category.categoryName, key: Key("name$index"))),
            if (!ResponsiveBreakpoints.of(context).isMobile)
              Expanded(
                  child: Text(category.description,
                      key: Key("description$index"),
                      textAlign: TextAlign.center)),
            Expanded(
                child: Text("${category.nbrOfProducts}",
                    key: Key("products$index"), textAlign: TextAlign.center)),
          ],
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) => BlocProvider.value(
                  value: categoryBloc, child: CategoryDialog(category)));
        },
        trailing: IconButton(
          key: Key('delete$index'),
          icon: const Icon(Icons.delete_forever),
          onPressed: () {
            categoryBloc.add(CategoryDelete(category.copyWith(image: null)));
          },
        ));
  }
}
