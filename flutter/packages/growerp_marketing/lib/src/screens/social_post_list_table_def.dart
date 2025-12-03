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

import '../bloc/social_post_bloc.dart';
import '../bloc/social_post_event.dart';

TableData getSocialPostListTableData(Bloc bloc, String classificationId,
    BuildContext context, SocialPost item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  final SocialPostBloc? socialPostBloc = bloc is SocialPostBloc ? bloc : null;

  Future<void> confirmDelete() async {
    if (socialPostBloc == null || item.postId == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete Social Post'),
        content: Text(
          'Are you sure you want to delete post "${item.headline ?? item.pseudoId}"?',
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
      socialPostBloc.add(SocialPostDelete(item));
    }
  }

  TableRowContent buildDeleteAction(
      {double width = 10, bool showLabel = true}) {
    return TableRowContent(
      name: showLabel
          ? const Text('Actions', textAlign: TextAlign.start)
          : const Text(''),
      width: width,
      value: IconButton(
        key: Key('delete$index'),
        tooltip: 'Delete social post',
        icon: const Icon(Icons.delete),
        color: Colors.red.shade600,
        onPressed: item.postId == null
            ? null
            : () {
                confirmDelete();
              },
      ),
    );
  }

  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'ID',
      width: 15,
      value: Text(
        item.pseudoId ?? '',
        key: const Key('socialPostItem'),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('Type\nHeadline\nStatus', textAlign: TextAlign.start),
        width: 70,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.type, key: Key('type$index')),
            Text(item.headline?.truncate(40) ?? 'No headline',
                key: Key('headline$index')),
            Text(
              item.status,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        )));
    rowContent.add(buildDeleteAction(width: 8, showLabel: false));
  } else {
    // Desktop layout
    rowContent.add(TableRowContent(
      name: 'ID',
      width: 6,
      value: Text(
        item.pseudoId ?? '',
        key: const Key('socialPostItem'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Type',
      width: 10,
      value: Text(
        item.type,
        key: Key('item$index'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Headline',
      width: 25,
      value: Text(
        item.headline?.truncate(40) ?? 'No headline',
        key: Key('headline$index'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Platform',
      width: 10,
      value: Text(
        item.platform ?? '-',
        key: Key('platform$index'),
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Status',
      width: 10,
      value: Text(
        item.status,
      ),
    ));
    rowContent.add(TableRowContent(
      name: 'Scheduled',
      width: 15,
      value: Text(
        item.scheduledDate != null
            ? '${item.scheduledDate!.month}/${item.scheduledDate!.day}/${item.scheduledDate!.year}'
            : '-',
        key: Key('scheduledDate$index'),
      ),
    ));
    rowContent.add(buildDeleteAction(width: 8));
  }

  return TableData(
    rowHeight: isPhone ? 55 : 20,
    rowContent: rowContent,
  );
}
