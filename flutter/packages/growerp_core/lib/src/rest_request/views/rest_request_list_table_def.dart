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
import 'package:intl/intl.dart';

TableData getRestRequestListTableData(
  Bloc bloc,
  String classificationId,
  BuildContext context,
  RestRequest item,
  int index, {
  dynamic extra,
}) {
  final localizations = CoreLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  List<TableRowContent> rowContent = [];

  if (isPhone) {
    rowContent.add(
      TableRowContent(
        name: 'Time',
        width: 15,
        value: CircleAvatar(
          child: Text(
            item.dateTime != null
                ? DateFormat('HH:mm').format(item.dateTime!)
                : '',
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: Text(localizations.userRequestStatus, textAlign: TextAlign.start),
        width: 55,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.user?.firstName ?? ''} ${item.user?.lastName ?? ''}',
              key: Key('user$index'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              item.restRequestName?.truncate(25) ?? '',
              key: Key('request$index'),
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                Icon(
                  item.wasError == true ? Icons.error : Icons.check_circle,
                  color: item.wasError == true ? Colors.red : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.runningTimeMillis ?? 0}ms',
                  style: TextStyle(
                    color: (item.runningTimeMillis ?? 0) > 1000
                        ? Colors.orange
                        : Colors.green,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: 'IP',
        width: 30,
        value: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.serverIp ?? '',
              key: Key('ip$index'),
              style: const TextStyle(fontSize: 11),
            ),
            if (item.isSlowHit == true)
              const Icon(Icons.speed, color: Colors.orange, size: 16),
          ],
        ),
      ),
    );
  } else {
    rowContent.add(
      TableRowContent(
        name: Text(localizations.dateTime, textAlign: TextAlign.start),
        width: 12,
        value: Text(
          item.dateTime != null
              ? DateFormat('dd/MM HH:mm:ss').format(item.dateTime!)
              : '',
          key: Key('dateTime$index'),
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: Text(localizations.user, textAlign: TextAlign.start),
        width: 15,
        value: Text(
          '${item.user?.firstName ?? ''} ${item.user?.lastName ?? ''}',
          key: Key('user$index'),
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: 'Request Name',
        width: 25,
        value: Text(
          item.restRequestName ?? '',
          key: Key('request$index'),
          textAlign: TextAlign.left,
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: 'Status',
        width: 8,
        value: Icon(
          item.wasError == true ? Icons.error : Icons.check_circle,
          color: item.wasError == true ? Colors.red : Colors.green,
          key: Key('status$index'),
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: 'Time (ms)',
        width: 10,
        value: Text(
          '${item.runningTimeMillis ?? 0}',
          key: Key('runtime$index'),
          style: TextStyle(
            color: (item.runningTimeMillis ?? 0) > 1000
                ? Colors.orange
                : Colors.green,
          ),
        ),
      ),
    );
    rowContent.add(
      TableRowContent(
        name: 'Server IP',
        width: 15,
        value: Text(item.serverIp ?? '', key: Key('ip$index')),
      ),
    );
    if (item.isSlowHit == true) {
      rowContent.add(
        TableRowContent(
          name: 'Slow',
          width: 8,
          value: const Icon(Icons.speed, color: Colors.orange),
        ),
      );
    } else {
      rowContent.add(
        TableRowContent(name: 'Slow', width: 8, value: const Text('')),
      );
    }
  }

  return TableData(rowHeight: isPhone ? 65 : 25, rowContent: rowContent);
}
