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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_core.dart';

/// Access to one screen, per user group.
class SecurityDialog extends StatefulWidget {
  const SecurityDialog(this.menuItem, {super.key});

  final MenuItem menuItem;

  @override
  State<SecurityDialog> createState() => _SecurityDialogState();
}

class _SecurityDialogState extends State<SecurityDialog> {
  late Map<UserGroup, ScreenAccess> _access;

  /// The bloc is already in `success` when this dialog opens, so a bare
  /// status check would pop it before the user changed anything.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _access = {
      for (final group in grantableUserGroups)
        group: accessOf(widget.menuItem, group),
    };
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    final phone = isPhone(context);

    return BlocListener<SecurityBloc, SecurityState>(
      listener: (context, state) {
        if (state.status == SecurityStatus.failure) {
          setState(() => _saving = false);
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
        if (_saving && state.status == SecurityStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: Dialog(
        key: const Key('SecurityDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: widget.menuItem.title,
          width: phone ? 400 : 600,
          height: phone ? 560 : 500,
          child: _content(localizations),
        ),
      ),
    );
  }

  Widget _content(CoreLocalizations localizations) {
    return SingleChildScrollView(
      key: const Key('listView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.menuItem.route != null)
            _detail(localizations.screen, widget.menuItem.route!),
          if (widget.menuItem.widgetName != null)
            _detail('Widget', widget.menuItem.widgetName!),
          if (widget.menuItem.artifactGroupId != null)
            _detail(localizations.restDomain, widget.menuItem.artifactGroupId!),
          const SizedBox(height: 16),
          Text(
            localizations.writeImpliesView,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final group in grantableUserGroups) _groupRow(group, localizations),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  key: const Key('update'),
                  onPressed: _save,
                  child: Text(localizations.update),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text('$label:')),
        Expanded(
          child: Text(value, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );

  Widget _groupRow(UserGroup group, CoreLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(_groupLabel(group, localizations))),
          Expanded(
            child: SegmentedButton<ScreenAccess>(
              key: Key('access-${group.name}'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ScreenAccess.none,
                  label: Text(localizations.accessNone),
                ),
                ButtonSegment(
                  value: ScreenAccess.view,
                  label: Text(localizations.accessView),
                ),
                ButtonSegment(
                  value: ScreenAccess.write,
                  label: Text(localizations.accessWrite),
                ),
              ],
              selected: {_access[group]!},
              onSelectionChanged: (selection) =>
                  setState(() => _access[group] = selection.first),
            ),
          ),
        ],
      ),
    );
  }

  String _groupLabel(UserGroup group, CoreLocalizations localizations) {
    switch (group) {
      case UserGroup.admin:
        return localizations.adminGroup;
      case UserGroup.employee:
        return localizations.employeeGroup;
      default:
        return localizations.otherGroup;
    }
  }

  void _save() {
    // Write implies view, so a write group is always sent in both lists.
    final see = <UserGroup>[];
    final write = <UserGroup>[];
    for (final entry in _access.entries) {
      if (entry.value == ScreenAccess.none) continue;
      see.add(entry.key);
      if (entry.value == ScreenAccess.write) write.add(entry.key);
    }
    // Always an explicit list: an empty one now means "the internal groups"
    // rather than "everyone", so collapsing a full selection to [] would
    // silently revoke the outside group.
    setState(() => _saving = true);
    context.read<SecurityBloc>().add(
      SecurityUpdate(
        menuItemId: widget.menuItem.menuItemId!,
        userGroups: see,
        updateGroups: write,
      ),
    );
  }
}
