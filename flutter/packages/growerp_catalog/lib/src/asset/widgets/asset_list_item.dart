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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../asset.dart';

class AssetListItem extends StatelessWidget {
  const AssetListItem({Key? key, required this.asset, required this.index})
      : super(key: key);

  final Asset asset;
  final int index;

  @override
  Widget build(BuildContext context) {
    final assetBloc = context.read<AssetBloc>();
    return ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(asset.assetName != null ? asset.assetName![0] : "?"),
        ),
        title: Row(
          children: <Widget>[
            Expanded(child: Text("${asset.assetName}", key: Key('name$index'))),
            Expanded(
                child: Text("${asset.product!.productName}",
                    key: Key('product$index'), textAlign: TextAlign.center)),
            Expanded(
                child: Text(asset.statusId == 'Deactivated' ? 'N' : 'Y',
                    key: Key('status$index'), textAlign: TextAlign.center)),
          ],
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: true,
              context: context,
              builder: (BuildContext context) => BlocProvider.value(
                  value: assetBloc, child: AssetDialog(asset)));
        },
        trailing: asset.statusId == 'Available' || asset.statusId == 'In Use'
            ? IconButton(
                key: Key('delete$index'),
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                  assetBloc.add(
                      AssetUpdate(asset.copyWith(statusId: 'Deactivated')));
                })
            : IconButton(
                key: Key('delete$index'),
                icon: const Icon(Icons.event_available),
                onPressed: () {
                  assetBloc
                      .add(AssetUpdate(asset.copyWith(statusId: 'Available')));
                },
              ));
  }
}
