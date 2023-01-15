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
import '../blocs/asset_bloc.dart';

class AssetListHeader extends StatefulWidget {
  const AssetListHeader({Key? key}) : super(key: key);

  @override
  State<AssetListHeader> createState() => _AssetListHeaderState();
}

class _AssetListHeaderState extends State<AssetListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    final assetBloc = context.read<AssetBloc>();
    return Material(
        child: ListTile(
            leading: GestureDetector(
                key: const Key('search'),
                onTap: (() =>
                    setState(() => search ? search = false : search = true)),
                child: Image.asset(
                  'assets/images/search.png',
                  height: 30,
                )),
            title: search
                ? Row(children: <Widget>[
                    Expanded(
                        child: TextField(
                      key: const Key('searchField'),
                      textInputAction: TextInputAction.go,
                      autofocus: true,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        hintText: "search in ID, name and description...",
                      ),
                      onChanged: ((value) => setState(() {
                            searchString = value;
                          })),
                    )),
                    ElevatedButton(
                        key: const Key('searchButton'),
                        child: const Text('Search'),
                        onPressed: () {
                          assetBloc.add(AssetFetch(searchString: searchString));
                        })
                  ])
                : Column(children: [
                    Row(children: <Widget>[
                      const Expanded(
                          child: Text("Name[ID]", textAlign: TextAlign.center)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                        const Expanded(
                            child: Text("Status", textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text("Product", textAlign: TextAlign.center)),
                    ]),
                    const Divider(color: Colors.black),
                  ]),
            trailing: const Text(' ')));
  }
}
