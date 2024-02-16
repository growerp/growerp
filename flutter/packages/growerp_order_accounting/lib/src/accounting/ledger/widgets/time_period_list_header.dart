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
import 'package:global_configuration/global_configuration.dart';
import 'package:responsive_framework/responsive_framework.dart';

class TimePeriodListHeader extends StatefulWidget {
  const TimePeriodListHeader({super.key});

  @override
  State<TimePeriodListHeader> createState() => _TimePeriodListHeaderState();
}

class _TimePeriodListHeaderState extends State<TimePeriodListHeader> {
  String classificationId = GlobalConfiguration().getValue("classificationId");
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() =>
                setState(() => search ? search = false : search = true)),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: Column(children: [
          Row(children: <Widget>[
            const Expanded(child: Text("Name", textAlign: TextAlign.left)),
            const Expanded(child: Text('Type', textAlign: TextAlign.left)),
            if (ResponsiveBreakpoints.of(context).equals(MOBILE))
              const Expanded(child: Text('Year', textAlign: TextAlign.left)),
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              const Expanded(child: Text('From', textAlign: TextAlign.left)),
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              const Expanded(child: Text('To', textAlign: TextAlign.left)),
            const Expanded(child: Text("Closed", textAlign: TextAlign.left)),
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
              Text('           ', textAlign: TextAlign.left),
          ]),
          const Divider(),
        ]),
        trailing: const Text(' '));
  }
}
