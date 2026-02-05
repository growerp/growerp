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

import '../blocs/subscription_bloc.dart';

/// Returns column definitions for the subscription list based on device type
List<StyledColumn> getSubscriptionColumns(bool isPhone) {
  if (isPhone) {
    return [
      const StyledColumn(header: 'Id', flex: 15),
      const StyledColumn(header: 'Subscriber\nEmail', flex: 45),
      const StyledColumn(header: 'From Date\nThru Date', flex: 25),
      const StyledColumn(header: '', flex: 15), // Actions
    ];
  } else {
    return [
      const StyledColumn(header: 'Id', flex: 8),
      const StyledColumn(header: 'Subscriber', flex: 20),
      const StyledColumn(header: 'Email', flex: 20),
      const StyledColumn(header: 'From Date', flex: 12),
      const StyledColumn(header: 'Thru Date', flex: 12),
      const StyledColumn(header: 'Purch. From', flex: 12),
      const StyledColumn(header: 'Purch. Thru', flex: 12),
      const StyledColumn(header: '', flex: 8), // Actions
    ];
  }
}

/// Builds a row for the subscription table
List<Widget> buildSubscriptionRow(
  BuildContext context,
  Subscription subscription,
  int index,
  bool isPhone,
) {
  final idWidget = Text(subscription.pseudoId ?? '', key: Key('id$index'));

  final subscriberWidget = Text(
    subscription.subscriber?.name ?? '',
    key: Key('subscriber$index'),
  );

  final emailWidget = Text(
    subscription.subscriber?.email ?? '',
    key: Key('email$index'),
  );

  final fromDateWidget = Text(
    subscription.fromDate.toLocalizedDateOnly(context),
    key: Key('fromDate$index'),
  );

  final thruDateWidget = Text(
    subscription.thruDate.toLocalizedDateOnly(context),
    key: Key('thruDate$index'),
  );

  final purchFromDateWidget = Text(
    subscription.purchaseFromDate.toLocalizedDateOnly(context),
    key: Key('purchFromDate$index'),
  );

  final purchThruDateWidget = Text(
    subscription.purchaseThruDate.toLocalizedDateOnly(context),
    key: Key('purchThruDate$index'),
  );

  final deleteButton = IconButton(
    key: Key('delete$index'),
    icon: const Icon(Icons.delete_forever),
    padding: EdgeInsets.zero,
    onPressed: () {
      context.read<SubscriptionBloc>().add(SubscriptionDelete(subscription));
    },
  );

  if (isPhone) {
    return [
      idWidget,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [subscriberWidget, emailWidget],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [fromDateWidget, thruDateWidget],
      ),
      deleteButton,
    ];
  } else {
    return [
      idWidget,
      subscriberWidget,
      emailWidget,
      fromDateWidget,
      thruDateWidget,
      purchFromDateWidget,
      purchThruDateWidget,
      deleteButton,
    ];
  }
}
