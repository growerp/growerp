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
import '../bloc/opportunity_bloc.dart';

class OpportunityListHeader extends StatefulWidget {
  const OpportunityListHeader({Key? key}) : super(key: key);

  @override
  State<OpportunityListHeader> createState() => _OpportunityListHeaderState();
}

class _OpportunityListHeaderState extends State<OpportunityListHeader> {
  String searchString = '';
  bool search = false;
  @override
  Widget build(BuildContext context) {
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
                    SizedBox(
                        width:
                            ResponsiveWrapper.of(context).isSmallerThan(TABLET)
                                ? MediaQuery.of(context).size.width - 250
                                : MediaQuery.of(context).size.width - 350,
                        child: TextField(
                          key: const Key('searchField'),
                          autofocus: true,
                          decoration: const InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            hintText: "search in ID, name and lead...",
                          ),
                          onChanged: ((value) => setState(() {
                                searchString = value;
                              })),
                        )),
                    ElevatedButton(
                        key: const Key('searchButton'),
                        child: const Text('Search'),
                        onPressed: () {
                          context.read<OpportunityBloc>().add(
                              OpportunityFetch(searchString: searchString));
                        })
                  ])
                : Column(children: [
                    Row(children: <Widget>[
                      const Expanded(
                          child: Text(
                        "Opportunity Name",
                      )),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                        const Expanded(
                            child: Text("Est. Amount",
                                textAlign: TextAlign.center)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                        const Expanded(
                            child: Text("Est. Probability %",
                                textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text("Lead Name & Company",
                              textAlign: TextAlign.left)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                        const Expanded(
                            child:
                                Text("Lead Email", textAlign: TextAlign.right)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                        const Expanded(
                            child: Text("Stage", textAlign: TextAlign.center)),
                      if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                        const Expanded(
                            child:
                                Text("Next Step", textAlign: TextAlign.center)),
                    ]),
                    const Divider(color: Colors.black),
                  ]),
            trailing: search ? null : const SizedBox(width: 20)));
  }
}