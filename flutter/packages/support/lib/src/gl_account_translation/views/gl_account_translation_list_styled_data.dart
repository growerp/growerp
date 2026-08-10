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

List<StyledColumn> getGlAccountTranslationListColumns(BuildContext context) {
  final localizations = SupportLocalizations.of(context)!;
  final isPhone = isAPhone(context);
  return [
    StyledColumn(header: localizations.tableHdrLanguage, flex: isPhone ? 3 : 2),
    StyledColumn(header: localizations.tableHdrStatus, flex: 2),
    if (!isPhone) StyledColumn(header: localizations.tableHdrNames, flex: 1),
    const StyledColumn(header: '', flex: 1),
  ];
}

List<Widget> getGlAccountTranslationListRow({
  required BuildContext context,
  required GlAccountTranslation translation,
  required int index,
  required void Function(GlAccountTranslation) onDelete,
}) {
  final isPhone = isAPhone(context);
  final counts = '${translation.translatedCount}/${translation.nameCount}';
  return [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${translation.language} (${translation.locale})',
          key: Key('language$index'),
          overflow: TextOverflow.ellipsis,
        ),
        if (isPhone)
          Text(counts, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
    Text(
      translation.status,
      key: Key('status$index'),
      style: TextStyle(
        color: translation.isCompleted
            ? Colors.green
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    if (!isPhone) Text(counts, key: Key('nameCount$index')),
    translation.translatedCount == 0
        ? const SizedBox.shrink()
        : IconButton(
            key: Key('delete$index'),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Remove the translations of this language',
            onPressed: () => onDelete(translation),
          ),
  ];
}
