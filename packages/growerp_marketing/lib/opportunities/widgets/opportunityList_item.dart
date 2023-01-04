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
import '../opportunities.dart';

class OpportunityListItem extends StatelessWidget {
  const OpportunityListItem(
      {Key? key, required this.opportunity, required this.index})
      : super(key: key);

  final Opportunity opportunity;
  final int index;

  @override
  Widget build(BuildContext context) {
    final _opportunityBloc = context.read<OpportunityBloc>();
    return Material(
        child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text("${opportunity.opportunityName![0]}"),
            ),
            title: Row(
              children: <Widget>[
                Expanded(
                    child: Text("${opportunity.opportunityName}",
                        key: Key('name$index'))),
                if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                  Expanded(
                      child: Text("${opportunity.estAmount.toString()}",
                          key: Key('estAmount$index'),
                          textAlign: TextAlign.center)),
                if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                  Expanded(
                      child: Text("${opportunity.estProbability.toString()}",
                          key: Key('estProbability$index'),
                          textAlign: TextAlign.center)),
                Expanded(
                    child: Text(
                  (opportunity.leadUser != null
                      ? "${opportunity.leadUser!.firstName} "
                          "${opportunity.leadUser!.lastName}, "
                          "${opportunity.leadUser!.companyName}"
                      : ""),
                  key: Key('lead$index'),
                )),
                if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                  Expanded(
                      child: Text(
                    opportunity.leadUser != null
                        ? "${opportunity.leadUser!.email}"
                        : "",
                    key: Key('leadEmail$index'),
                  )),
                if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET))
                  Text("${opportunity.stageId}",
                      key: Key('stageId$index'), textAlign: TextAlign.center),
                if (!ResponsiveWrapper.of(context).isSmallerThan(DESKTOP))
                  Expanded(
                      child: Text(
                          opportunity.nextStep != null
                              ? "${opportunity.nextStep}"
                              : "",
                          key: Key('nextStep$index'),
                          textAlign: TextAlign.center)),
              ],
            ),
            onTap: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return BlocProvider.value(
                        value: _opportunityBloc,
                        child: OpportunityDialog(opportunity));
                  });
            },
            trailing: IconButton(
              key: Key('delete$index'),
              icon: Icon(Icons.delete_forever),
              onPressed: () {
                _opportunityBloc.add(OpportunityDelete(opportunity));
              },
            )));
  }
}
