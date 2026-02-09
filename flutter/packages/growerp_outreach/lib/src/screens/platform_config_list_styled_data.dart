/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
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

/// Returns column definitions for platform config list based on device type
List<StyledColumn> getPlatformConfigListColumns(BuildContext context) {
  bool isPhone = isAPhone(context);

  if (isPhone) {
    return const [
      StyledColumn(header: '', flex: 1), // Status icon
      StyledColumn(header: 'Info', flex: 4),
      StyledColumn(header: '', flex: 1), // Actions
    ];
  }

  return const [
    StyledColumn(header: 'Platform', flex: 2),
    StyledColumn(header: 'Status', flex: 2),
    StyledColumn(header: 'Enabled', flex: 1),
    StyledColumn(header: 'Daily Limit', flex: 1),
    StyledColumn(header: 'Config ID', flex: 2),
    StyledColumn(header: '', flex: 1), // Actions
  ];
}

/// Returns row data for platform config list
List<Widget> getPlatformConfigListRow({
  required BuildContext context,
  required PlatformConfigData data,
  required int index,
  required PlatformConfigBloc bloc,
}) {
  bool isPhone = isAPhone(context);

  Future<void> confirmDelete() async {
    if (data.config?.configId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text(
          'Are you sure you want to delete the ${data.platform.name} configuration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: Key('deleteConfirm$index'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      bloc.add(PlatformConfigDelete(data.config!.configId!));
    }
  }

  List<Widget> cells = [];

  if (isPhone) {
    // Status icon
    cells.add(
      CircleAvatar(
        key: const Key('platformItem'),
        backgroundColor: data.isConfigured ? Colors.green : Colors.grey,
        child: Icon(
          data.isConfigured ? Icons.check : Icons.circle_outlined,
          color: Colors.white,
        ),
      ),
    );

    // Combined info cell
    cells.add(
      Column(
        key: Key('platformInfo$index'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.platform.name,
            key: Key('platform$index'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            data.isConfigured ? 'Configured' : 'Not Configured',
            key: Key('status$index'),
            style: TextStyle(
              fontSize: 12,
              color: data.isConfigured ? Colors.green : Colors.grey,
            ),
          ),
          Text(
            'Limit: ${data.config?.dailyLimit ?? "-"}',
            key: Key('limit$index'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  } else {
    // Platform with status icon
    cells.add(
      Row(
        children: [
          Icon(
            data.isConfigured ? Icons.check_circle : Icons.circle_outlined,
            color: data.isConfigured ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            data.platform.name,
            key: Key('platform$index'),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );

    // Status
    cells.add(
      Text(
        data.isConfigured ? 'Configured' : 'Not Configured',
        key: Key('status$index'),
        style: TextStyle(
          color: data.isConfigured ? Colors.green : Colors.grey,
        ),
      ),
    );

    // Enabled
    cells.add(
      Text(
        data.config?.isEnabled == true ? 'Yes' : 'No',
        key: Key('enabled$index'),
      ),
    );

    // Daily Limit
    cells.add(
      Text(
        data.config?.dailyLimit.toString() ?? '-',
        key: Key('dailyLimit$index'),
      ),
    );

    // Config ID
    cells.add(
      Text(
        data.config?.configId ?? '-',
        key: Key('configId$index'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Delete action
  cells.add(
    data.config?.configId == null
        ? const SizedBox.shrink()
        : IconButton(
            key: Key('delete$index'),
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete configuration',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: confirmDelete,
          ),
  );

  return cells;
}
