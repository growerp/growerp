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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';

class GlAccountListHeader extends StatefulWidget {
  const GlAccountListHeader({super.key});

  @override
  State<GlAccountListHeader> createState() => _GlAccountListHeaderState();
}

class _GlAccountListHeaderState extends State<GlAccountListHeader> {
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
      title: search
          ? Row(
              children: <Widget>[
                SizedBox(
                  width: isPhone(context)
                      ? MediaQuery.of(context).size.width - 250
                      : MediaQuery.of(context).size.width - 350,
                  child: TextField(
                    key: const Key('searchField'),
                    textInputAction: TextInputAction.search,
                    autofocus: true,
                    decoration: InputDecoration(
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      hintText: localizations.searchGlAccountHint,
                    ),
                    onChanged: ((value) => setState(() {
                      searchString = value;
                    })),
                  ),
                ),
                OutlinedButton(
                  key: const Key('searchButton'),
                  child: Text(localizations.search),
                  onPressed: () {
                    context.read<GlAccountBloc>().add(
                      GlAccountFetch(searchString: searchString),
                    );
                    searchString = '';
                  },
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPhone(context)) Text(localizations.accountName),
                Row(
                  children: [
                    Expanded(child: Text(localizations.accountCode)),
                    if (isLargerThanPhone(context))
                      Expanded(child: Text(localizations.accountName)),
                    if (isPhone(context))
                      Expanded(
                        child: Text(
                          localizations.debit,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    if (isLargerThanPhone(context))
                      Expanded(
                        child: Text(
                          localizations.accountClass,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (isLargerThanPhone(context))
                      Expanded(
                        child: Text(
                          localizations.accountType,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (isPhone(context))
                      Expanded(
                        child: Text(
                          localizations.credit,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    if (isLargerThanPhone(context))
                      Expanded(
                        child: Text(
                          localizations.debit,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    if (isLargerThanPhone(context))
                      Expanded(
                        child: Text(
                          localizations.credit,
                          textAlign: TextAlign.right,
                        ),
                      ),
                  ],
                ),
                const Divider(),
              ],
            ),
      trailing: search ? null : const SizedBox(width: 20),
    );
  }
}
