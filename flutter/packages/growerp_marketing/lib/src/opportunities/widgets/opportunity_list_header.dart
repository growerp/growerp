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

import '../../l10n/generated/marketing_localizations.dart';
import '../bloc/opportunity_bloc.dart';

class OpportunityListHeader extends StatefulWidget {
  const OpportunityListHeader({super.key});

  @override
  State<OpportunityListHeader> createState() => _OpportunityListHeaderState();
}

class _OpportunityListHeaderState extends State<OpportunityListHeader> {
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
                      context
                          .read<OpportunityBloc>()
                          .add(OpportunityFetch(searchString: searchString));
                    })
              ])
            : Column(children: [
                Row(children: <Widget>[
                  Expanded(
                      child: Text(
                    MarketingLocalizations.of(context)!.opportunityName,
                  )),
                  if (ResponsiveBreakpoints.of(context).isDesktop)
                    const Expanded(
                        child:
                            Text("Est. Amount", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).isDesktop)
                    const Expanded(
                        child: Text("Est. Probability %",
                            textAlign: TextAlign.center)),
                  const Expanded(
                      child: Text("Lead Name & Company",
                          textAlign: TextAlign.left)),
                  if (ResponsiveBreakpoints.of(context).isDesktop)
                    const Expanded(
                        child: Text("Lead Email", textAlign: TextAlign.right)),
                  if (!ResponsiveBreakpoints.of(context).isMobile)
                    const Expanded(
                        child: Text("Stage", textAlign: TextAlign.center)),
                  if (ResponsiveBreakpoints.of(context).isDesktop)
                    const Expanded(
                        child: Text("Next Step", textAlign: TextAlign.center)),
                ]),
                const Divider(),
              ]),
        trailing: search ? null : const SizedBox(width: 20));
  }
}
