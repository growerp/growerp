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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../gl_account.dart';

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
    return ListTile(
        leading: GestureDetector(
            key: const Key('search'),
            onTap: (() =>
                setState(() => search ? search = false : search = true)),
            child: const Icon(Icons.search_sharp, size: 40)),
        title: search
            ? Row(children: <Widget>[
                SizedBox(
                    width: ResponsiveBreakpoints.of(context).isMobile
                        ? MediaQuery.of(context).size.width - 250
                        : MediaQuery.of(context).size.width - 350,
                    child: TextField(
                      key: const Key('searchField'),
                      autofocus: true,
                      decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        hintText: "search in ID, name ...",
                      ),
                      onChanged: ((value) => setState(() {
                            searchString = value;
                          })),
                    )),
                ElevatedButton(
                    key: const Key('searchButton'),
                    child: const Text('Search'),
                    onPressed: () {
                      context
                          .read<GlAccountBloc>()
                          .add(GlAccountFetch(searchString: searchString));
                      searchString = '';
                    })
              ])
            : Column(children: [
                if (ResponsiveBreakpoints.of(context).equals(MOBILE))
                  const Text("Account name", textAlign: TextAlign.left),
                Row(children: [
                  const Expanded(child: Text("Account code")),
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                    const Expanded(
                        child:
                            Text("Account name", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).equals(MOBILE))
                    const Expanded(
                        child: Text("debit", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                    const Expanded(
                        child:
                            Text("Account class", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                    const Expanded(
                        child:
                            Text("Account Type", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).equals(MOBILE))
                    const Expanded(
                        child: Text("Credit", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                    const Expanded(
                        child: Text("Debit", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
                    const Expanded(
                        child: Text("Credit", textAlign: TextAlign.center)),
                ]),
                const Divider(),
              ]),
        trailing: search ? null : const SizedBox(width: 20));
  }
}
