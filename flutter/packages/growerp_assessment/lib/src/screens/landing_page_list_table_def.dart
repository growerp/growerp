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

TableData getLandingPageListTableData(Bloc bloc, String classificationId,
    BuildContext context, LandingPage item, int index,
    {dynamic extra}) {
  bool isPhone = isAPhone(context);
  List<TableRowContent> rowContent = [];
  if (isPhone) {
    rowContent.add(TableRowContent(
      name: 'ID',
      width: isPhone ? 10 : 5,
      value: CircleAvatar(
        child: Text(
          item.pseudoId == null ? '' : item.pseudoId!.lastChar(3),
          key: const Key('landingPageItem'),
        ),
      ),
    ));
    rowContent.add(TableRowContent(
        name: const Text('ID\nTitle\nStatus', textAlign: TextAlign.start),
        width: 40,
        value: Column(
          key: Key('item$index'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.pseudoId ?? '', key: Key('id$index')),
            Text(item.title.truncate(18), key: Key('title$index')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.status == 'ACTIVE'
                    ? Colors.green
                    : item.status == 'PUBLISHED'
                        ? Colors.blue
                        : item.status == 'DRAFT'
                            ? Colors.orange
                            : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                key: Key('status$index'),
              ),
            ),
          ],
        )));
  } else {
    rowContent.add(TableRowContent(
        name: const Text('ID', textAlign: TextAlign.start),
        width: 8,
        value: Text(
          item.pseudoId ?? '',
          key: Key('id$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Title', textAlign: TextAlign.start),
        width: 25,
        value: Text(
          item.title,
          key: Key('title$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Headline', textAlign: TextAlign.start),
        width: 25,
        value: Text(
          item.headline ?? 'N/A',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          key: Key('headline$index'),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Status', textAlign: TextAlign.start),
        width: 10,
        value: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: item.status == 'ACTIVE'
                ? Colors.green
                : item.status == 'PUBLISHED'
                    ? Colors.blue
                    : item.status == 'DRAFT'
                        ? Colors.orange
                        : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            key: Key('status$index'),
          ),
        )));
    rowContent.add(TableRowContent(
        name: const Text('Hook Type', textAlign: TextAlign.start),
        width: 12,
        value: Text(
          item.hookType ?? 'N/A',
          textAlign: TextAlign.left,
          key: Key('hookType$index'),
        )));
  }
  return TableData(
    rowHeight: isPhone ? 65 : 20,
    rowContent: rowContent,
  );
}
