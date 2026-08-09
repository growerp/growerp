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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../blocs/subscription_bloc.dart';
import 'package:growerp_catalog/l10n/generated/catalog_localizations.dart';

/// Returns column definitions for the subscription list based on device type
List<StyledColumn> getSubscriptionColumns(BuildContext context, bool isPhone) {
  final localizations = CatalogLocalizations.of(context)!;
  if (isPhone) {
    return [
      StyledColumn(header: localizations.tableHdrId, flex: 15),
      StyledColumn(header: localizations.tableHdrSubscriberEmail, flex: 45),
      StyledColumn(header: localizations.tableHdrFromThruDate, flex: 25),
      const StyledColumn(header: '', flex: 15), // Actions
    ];
  } else {
    return [
      StyledColumn(header: localizations.tableHdrId, flex: 8),
      StyledColumn(header: localizations.subscriberLabel, flex: 20),
      StyledColumn(header: localizations.tableHdrEmail, flex: 20),
      StyledColumn(header: localizations.fromDate, flex: 12),
      StyledColumn(header: localizations.thruDate, flex: 12),
      StyledColumn(header: localizations.tableHdrPurchFrom, flex: 12),
      StyledColumn(header: localizations.tableHdrPurchThru, flex: 12),
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
