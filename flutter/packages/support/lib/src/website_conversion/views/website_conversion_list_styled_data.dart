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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

List<StyledColumn> getWebsiteConversionListColumns(BuildContext context) {
  final isPhone = isAPhone(context);
  return [
    StyledColumn(header: 'Website', flex: isPhone ? 3 : 2),
    if (!isPhone) const StyledColumn(header: 'Company', flex: 2),
    const StyledColumn(header: 'Status', flex: 2),
    if (!isPhone) const StyledColumn(header: 'Pages', flex: 1),
    const StyledColumn(header: '', flex: 1),
  ];
}

Color _statusColor(BuildContext context, WebsiteConversion conversion) {
  final scheme = Theme.of(context).colorScheme;
  if (conversion.isFailed) return scheme.error;
  if (conversion.isCompleted) return Colors.green;
  return scheme.onSurfaceVariant;
}

List<Widget> getWebsiteConversionListRow({
  required BuildContext context,
  required WebsiteConversion conversion,
  required int index,
  required void Function(WebsiteConversion) onExport,
}) {
  final isPhone = isAPhone(context);
  return [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          conversion.sourceUrl.replaceFirst(RegExp(r'^https?://'), ''),
          key: Key('sourceUrl$index'),
          overflow: TextOverflow.ellipsis,
        ),
        if (isPhone)
          Text(
            conversion.companyName,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
    if (!isPhone)
      Text(
        conversion.companyName,
        key: Key('companyName$index'),
        overflow: TextOverflow.ellipsis,
      ),
    Row(
      children: [
        if (conversion.inProgress)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Flexible(
          child: Text(
            conversion.status,
            key: Key('status$index'),
            style: TextStyle(color: _statusColor(context, conversion)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    if (!isPhone)
      Text(
        conversion.pageCount == null
            ? ''
            : '${conversion.pageCount}/${conversion.imageCount ?? 0}',
        key: Key('pageCount$index'),
      ),
    // only a finished website has something to export
    conversion.isCompleted
        ? IconButton(
            key: Key('export$index'),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.download),
            tooltip: 'Save as an import file for another installation',
            onPressed: () => onExport(conversion),
          )
        : const SizedBox.shrink(),
  ];
}
