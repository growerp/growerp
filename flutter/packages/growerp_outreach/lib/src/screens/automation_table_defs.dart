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
import '../bloc/outreach_campaign_bloc.dart';

TableData getActiveCampaignsTableData(Bloc bloc, String classificationId,
    BuildContext context, OutreachCampaign item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'Campaign',
      width: 40,
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(item.status,
              style: TextStyle(
                  color: item.status == 'ACTIVE' ? Colors.green : Colors.grey)),
        ],
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Action',
      width: 20,
      value: IconButton(
        icon: Icon(
            item.status == 'ACTIVE'
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: item.status == 'ACTIVE' ? Colors.orange : Colors.green),
        onPressed: () {
          if (item.campaignId != null) {
            final outreachBloc = bloc as OutreachCampaignBloc;
            if (item.status == 'ACTIVE') {
              outreachBloc.add(OutreachCampaignPause(item.campaignId!));
            } else {
              outreachBloc.add(OutreachCampaignStart(item.campaignId!));
            }
          }
        },
      ),
    ));
  } else {
    rowContent.add(TableRowContent(
        name: 'Name',
        width: 20,
        value: Text(item.name, key: Key('name$index'))));
    rowContent.add(TableRowContent(
        name: 'Status',
        width: 10,
        value: Text(item.status,
            style: TextStyle(
                color: item.status == 'ACTIVE' ? Colors.green : Colors.grey))));
    rowContent.add(TableRowContent(
      name: 'Action',
      width: 10,
      value: IconButton(
        icon: Icon(
            item.status == 'ACTIVE'
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: item.status == 'ACTIVE' ? Colors.orange : Colors.green),
        onPressed: () {
          if (item.campaignId != null) {
            final outreachBloc = bloc as OutreachCampaignBloc;
            if (item.status == 'ACTIVE') {
              outreachBloc.add(OutreachCampaignPause(item.campaignId!));
            } else {
              outreachBloc.add(OutreachCampaignStart(item.campaignId!));
            }
          }
        },
      ),
    ));
  }

  return TableData(
    rowHeight: isPhone ? 60 : 50,
    rowContent: rowContent,
  );
}

TableData getRecentActivityTableData(Bloc bloc, String classificationId,
    BuildContext context, OutreachMessage item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'Message',
      width: 60,
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.recipientName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${item.platform} • ${item.status}',
              style: TextStyle(
                  fontSize: 12,
                  color: item.status == 'FAILED' ? Colors.red : Colors.grey)),
        ],
      ),
    ));
  } else {
    rowContent.add(TableRowContent(
        name: 'Recipient',
        width: 15,
        value: Text(item.recipientName ?? 'Unknown')));
    rowContent.add(TableRowContent(
        name: 'Platform', width: 10, value: Text(item.platform)));
    rowContent.add(TableRowContent(
        name: 'Status',
        width: 10,
        value: Text(item.status,
            style: TextStyle(
                color: item.status == 'FAILED'
                    ? Colors.red
                    : item.status == 'SENT'
                        ? Colors.green
                        : Colors.grey))));
    rowContent.add(TableRowContent(
        name: 'Error',
        width: 20,
        value: Text(item.errorMessage ?? '',
            style: const TextStyle(color: Colors.red),
            overflow: TextOverflow.ellipsis)));
  }

  return TableData(
    rowHeight: isPhone ? 60 : 40,
    rowContent: rowContent,
  );
}
