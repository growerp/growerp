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
import 'package:growerp_models/growerp_models.dart';

/// Groups an organization can grant. GROWERP_M_SYSTEM is deliberately absent:
/// system access is not the organization's to hand out, and set#MenuItemGroups
/// rejects it server side as well.
const List<UserGroup> grantableUserGroups = [
  UserGroup.admin,
  UserGroup.employee,
  UserGroup.other,
];

/// What one group may do with one screen.
enum ScreenAccess { none, view, write }

ScreenAccess accessOf(MenuItem item, UserGroup group) {
  final see = item.userGroups;
  // Same default as the backend: no list means the internal groups only, so an
  // outside user reaches a screen only when it names their group.
  final canSee = see == null || see.isEmpty
      ? group != UserGroup.other
      : see.contains(group);
  if (!canSee) return ScreenAccess.none;
  final write = item.updateGroups;
  // Absent write list: write follows view, matching check#RestAccess. Most seed
  // screens name no writers and are writable by the internal groups today, so
  // showing them read-only would be a lie. An *empty* list is different: it means
  // the screen was explicitly set to read-only for everyone.
  if (write == null) {
    return group == UserGroup.other ? ScreenAccess.view : ScreenAccess.write;
  }
  if (write.contains(group)) return ScreenAccess.write;
  return ScreenAccess.view;
}

/// Chip showing one cell of the grid.
class AccessChip extends StatelessWidget {
  const AccessChip({super.key, required this.access, required this.label});

  final ScreenAccess access;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    late final Color background;
    late final Color foreground;
    switch (access) {
      case ScreenAccess.none:
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
        break;
      case ScreenAccess.view:
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        break;
      case ScreenAccess.write:
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: foreground),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
