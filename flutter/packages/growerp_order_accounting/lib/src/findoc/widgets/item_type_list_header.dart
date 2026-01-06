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
import 'package:responsive_framework/responsive_framework.dart';

import '../findoc.dart';

class ItemTypeListHeader extends StatefulWidget {
  const ItemTypeListHeader({super.key});

  @override
  State<ItemTypeListHeader> createState() => _ItemTypeListHeaderState();
}

class _ItemTypeListHeaderState extends State<ItemTypeListHeader> {
  String classificationId = GlobalConfiguration().getValue("classificationId");
  String searchString = '';
  bool search = false;

  @override
  Widget build(BuildContext context) {
    final finDocBloc = context.read<FinDocBloc>();
    return Column(
      children: [
        ListTile(
          leading: GestureDetector(
            key: const Key('search'),
            onTap: (() {
              setState(() => search = !search);
              if (!search) finDocBloc.add(const FinDocGetItemTypes());
            }),
            child: const Icon(Icons.search_sharp, size: 40),
          ),
          title: search
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        key: const Key('searchField'),
                        textInputAction: TextInputAction.go,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "search item type or account",
                        ),
                        onChanged: ((value) => setState(() {
                          searchString = value;
                        })),
                      ),
                    ),
                    OutlinedButton(
                      key: const Key('searchButton'),
                      child: const Text('Search'),
                      onPressed: () {
                        finDocBloc.add(
                          FinDocGetItemTypes(searchString: searchString),
                        );
                      },
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Item Type  Dir: In/Out',
                        textAlign: TextAlign.left,
                      ),
                    ),
                    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                      const Expanded(
                        child: Text(
                          'Account Code Account Name',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                      const Text('        ', textAlign: TextAlign.left),
                  ],
                ),
          subtitle: ResponsiveBreakpoints.of(context).equals(MOBILE)
              ? const Text('Account Code  Account Name')
              : null,
          trailing: const Text(' '),
        ),
        const Divider(),
      ],
    );
  }
}
