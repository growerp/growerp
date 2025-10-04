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
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
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
    final localizations = OrderAccountingLocalizations.of(context)!;
    return ListTile(
      leading: GestureDetector(
        key: const Key('search'),
        onTap: (() => setState(() => search ? search = false : search = true)),
        child: const Icon(Icons.search_sharp, size: 40),
      ),
      title: Column(
        children: [
          Row(
            children: <Widget>[
              Expanded(
                child: Text(localizations.name, textAlign: TextAlign.left),
              ),
              Expanded(
                child: Text(localizations.type, textAlign: TextAlign.left),
              ),
              if (ResponsiveBreakpoints.of(context).equals(MOBILE))
                Expanded(
                  child: Text(localizations.year, textAlign: TextAlign.left),
                ),
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                Expanded(
                  child: Text(localizations.from, textAlign: TextAlign.left),
                ),
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                Expanded(
                  child: Text(localizations.to, textAlign: TextAlign.left),
                ),
              Expanded(
                child: Text(localizations.closed, textAlign: TextAlign.left),
              ),
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                const Text('           ', textAlign: TextAlign.left),
            ],
          ),
          const Divider(),
        ],
      ),
      trailing: const Text(' '),
    );
  }
}
