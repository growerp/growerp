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

import '../bloc/platform_config_bloc.dart';

/// Platform configuration data for table display
class PlatformConfigData {
  final OutreachPlatform platform;
  final PlatformConfiguration? config;

  const PlatformConfigData({
    required this.platform,
    this.config,
  });

  bool get isConfigured => config != null;
}

TableData getPlatformConfigListTableData(
  Bloc bloc,
  String classificationId,
  BuildContext context,
  PlatformConfigData item,
  int index, {
  dynamic extra,
}) {
  bool isPhone = isAPhone(context);
  final PlatformConfigBloc? platformConfigBloc =
      bloc is PlatformConfigBloc ? bloc : null;

  Future<void> confirmDelete() async {
    if (platformConfigBloc == null || item.config?.configId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text(
          'Are you sure you want to delete the ${item.platform.displayName} configuration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: Key('deleteConfirm$index'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      platformConfigBloc.add(PlatformConfigDelete(item.config!.configId!));
    }
  }

  TableRowContent buildDeleteAction({
    double width = 8,
    bool showLabel = true,
  }) {
    return TableRowContent(
      name: showLabel
          ? const Text('', textAlign: TextAlign.start)
          : const Text(''),
      width: width,
      value: item.config?.configId == null
          ? const SizedBox.shrink()
          : IconButton(
              key: Key('delete$index'),
              tooltip: 'Delete configuration',
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red.shade600,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => confirmDelete(),
            ),
    );
  }

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'Platform',
      width: 15,
      value: CircleAvatar(
        backgroundColor: item.isConfigured ? Colors.green : Colors.grey,
        child: Icon(
          item.isConfigured ? Icons.check : Icons.circle_outlined,
          color: Colors.white,
        ),
      ),
    ));
    rowContent.add(TableRowContent(
      name: const Text('Platform\\nStatus\\nLimit', textAlign: TextAlign.start),
      width: 70,
      value: Column(
        key: Key('item$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.platform.displayName, key: Key('platform$index')),
          Text(
            item.isConfigured ? 'Configured' : 'Not Configured',
            key: Key('status$index'),
          ),
          Text(
            'Limit: ${item.config?.dailyLimit ?? "-"}',
            key: Key('limit$index'),
          ),
        ],
      ),
    ));
    rowContent.add(buildDeleteAction(width: 15, showLabel: false));
  } else {
    rowContent.add(TableRowContent(
      name: const Text('Platform', textAlign: TextAlign.start),
      width: 15,
      value: Row(
        children: [
          Icon(
            item.isConfigured ? Icons.check_circle : Icons.circle_outlined,
            color: item.isConfigured ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            item.platform.displayName,
            key: Key('platform$index'),
          ),
        ],
      ),
    ));
    rowContent.add(TableRowContent(
      name: const Text('Status', textAlign: TextAlign.start),
      width: 25,
      value: Text(
        item.isConfigured ? 'Configured' : 'Not Configured',
        key: Key('status$index'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: const Text('Enabled', textAlign: TextAlign.start),
      width: 10,
      value: Text(
        item.config?.isEnabled == true ? 'Yes' : 'No',
        key: Key('enabled$index'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: const Text('Daily Limit', textAlign: TextAlign.start),
      width: 15,
      value: Text(
        item.config?.dailyLimit.toString() ?? '-',
        key: Key('dailyLimit$index'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: const Text('Config ID', textAlign: TextAlign.start),
      width: 12,
      value: Text(
        item.config?.configId ?? '-',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        key: Key('configId$index'),
      ),
    ));
    rowContent.add(buildDeleteAction());
  }
  return TableData(
    rowHeight: isPhone ? 65 : 20,
    rowContent: rowContent,
  );
}
