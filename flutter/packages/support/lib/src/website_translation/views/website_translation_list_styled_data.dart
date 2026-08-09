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
import 'package:support/l10n/generated/support_localizations.dart';

List<StyledColumn> getWebsiteTranslationListColumns(BuildContext context) {
  final localizations = SupportLocalizations.of(context)!;
  final isPhone = isAPhone(context);
  return [
    StyledColumn(header: localizations.tableHdrOwner, flex: isPhone ? 3 : 2),
    if (!isPhone)
      StyledColumn(header: localizations.tableHdrLanguages, flex: 2),
    StyledColumn(header: localizations.tableHdrStatus, flex: 2),
    if (!isPhone) StyledColumn(header: localizations.tableHdrPages, flex: 1),
    const StyledColumn(header: '', flex: 1),
  ];
}

Color _statusColor(BuildContext context, WebsiteTranslation translation) {
  final scheme = Theme.of(context).colorScheme;
  if (translation.isFailed) return scheme.error;
  if (translation.isCompleted) return Colors.green;
  return scheme.onSurfaceVariant;
}

List<Widget> getWebsiteTranslationListRow({
  required BuildContext context,
  required WebsiteTranslation translation,
  required int index,
  required void Function(WebsiteTranslation) onDelete,
}) {
  final isPhone = isAPhone(context);
  final owner = translation.ownerName.isEmpty
      ? translation.ownerPartyId
      : translation.ownerName;
  return [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          owner,
          key: Key('ownerName$index'),
          overflow: TextOverflow.ellipsis,
        ),
        if (isPhone)
          Text(
            translation.targetLanguageNames,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    ),
    if (!isPhone)
      Text(
        translation.targetLanguageNames,
        key: Key('targetLocales$index'),
        overflow: TextOverflow.ellipsis,
      ),
    Row(
      children: [
        if (translation.inProgress)
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
            translation.status,
            key: Key('status$index'),
            style: TextStyle(color: _statusColor(context, translation)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    if (!isPhone)
      Text(
        translation.pageCount == null
            ? ''
            : '${translation.translatedCount ?? 0}/${translation.pageCount}',
        key: Key('pageCount$index'),
      ),
    // a running translation must not have its row pulled away underneath it
    translation.inProgress
        ? const SizedBox.shrink()
        : IconButton(
            key: Key('delete$index'),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Remove this row, the translated pages stay',
            onPressed: () => onDelete(translation),
          ),
  ];
}
