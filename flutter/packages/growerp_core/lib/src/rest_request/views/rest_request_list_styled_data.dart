/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

List<StyledColumn> getRestRequestListColumns(BuildContext context) {
  final localizations = CoreLocalizations.of(context)!;
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      const StyledColumn(header: 'Time', flex: 1),
      StyledColumn(header: localizations.userRequestStatus, flex: 4),
      const StyledColumn(header: 'IP', flex: 2),
    ];
  }
  return [
    StyledColumn(header: localizations.dateTime, flex: 2),
    StyledColumn(header: localizations.user, flex: 2),
    const StyledColumn(header: 'Company Name', flex: 2),
    const StyledColumn(header: 'Request Name', flex: 3),
    const StyledColumn(header: 'Status', flex: 1),
    const StyledColumn(header: 'Time (ms)', flex: 1),
    const StyledColumn(header: 'Server IP', flex: 2),
    const StyledColumn(header: 'Slow', flex: 1),
  ];
}

List<Widget> getRestRequestListRow({
  required BuildContext context,
  required RestRequest request,
  required int index,
}) {
  bool isPhone = isAPhone(context);
  if (isPhone) {
    return [
      CircleAvatar(
        child: Text(
          request.dateTime != null
              ? DateFormat('HH:mm').format(request.dateTime!)
              : '',
          style: const TextStyle(fontSize: 10),
        ),
      ),
      Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${request.user?.firstName ?? ''} ${request.user?.lastName ?? ''}',
            key: Key('user$index'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            request.restRequestName?.truncate(25) ?? '',
            key: Key('request$index'),
            style: const TextStyle(fontSize: 12),
          ),
          Row(
            children: [
              Icon(
                request.wasError == true ? Icons.error : Icons.check_circle,
                color: request.wasError == true ? Colors.red : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${request.runningTimeMillis ?? 0}ms',
                style: TextStyle(
                  color: (request.runningTimeMillis ?? 0) > 1000
                      ? Colors.orange
                      : Colors.green,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            request.serverIp ?? '',
            key: Key('ip$index'),
            style: const TextStyle(fontSize: 11),
          ),
          if (request.isSlowHit == true)
            const Icon(Icons.speed, color: Colors.orange, size: 16),
        ],
      ),
    ];
  }
  return [
    Text(
      request.dateTime != null
          ? DateFormat('dd/MM HH:mm:ss').format(request.dateTime!)
          : '',
      key: Key('dateTime$index'),
    ),
    Text(
      '${request.user?.firstName ?? ''} ${request.user?.lastName ?? ''}',
      key: Key('user$index'),
    ),
    Text(request.companyName ?? '', key: Key('company$index')),
    Text(
      request.restRequestName ?? '',
      key: Key('request$index'),
      textAlign: TextAlign.left,
    ),
    Icon(
      request.wasError == true ? Icons.error : Icons.check_circle,
      color: request.wasError == true ? Colors.red : Colors.green,
      key: Key('status$index'),
    ),
    Text(
      '${request.runningTimeMillis ?? 0}',
      key: Key('runtime$index'),
      style: TextStyle(
        color: (request.runningTimeMillis ?? 0) > 1000
            ? Colors.orange
            : Colors.green,
      ),
    ),
    Text(request.serverIp ?? '', key: Key('ip$index')),
    request.isSlowHit == true
        ? const Icon(Icons.speed, color: Colors.orange)
        : const Text(''),
  ];
}
