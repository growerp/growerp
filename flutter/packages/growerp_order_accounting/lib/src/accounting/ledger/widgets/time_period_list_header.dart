/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
  String applicationId = GlobalConfiguration().getValue("applicationId");
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
