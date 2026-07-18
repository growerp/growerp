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

import 'app_blocks.dart';

/// The AI-produced description of a new vertical. Deliberately minimal: the AI
/// only chooses a name, a human title and a set of registered block keys. The
/// deterministic scaffold derives menu items, routes and widget names from the
/// block registry — the AI never emits those, so it cannot break the
/// widgetName↔registry contract.
class VerticalSpec {
  final String name;
  final String appTitle;
  final List<String> blocks;

  const VerticalSpec({
    required this.name,
    required this.appTitle,
    required this.blocks,
  });

  /// Parses and validates a spec from decoded JSON.
  /// Throws [FormatException] with an actionable message when invalid; the
  /// message is fed back to the model for a single retry.
  factory VerticalSpec.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      throw FormatException(
        'Invalid "name": "$name". Must be lowercase, start with a letter, '
        'and use only letters, numbers and underscores.',
      );
    }

    final rawBlocks = (json['blocks'] as List?)?.cast<String>() ?? const [];
    final blocks = rawBlocks.map((b) => b.trim()).toList();
    final unknown = unknownBlockKeys(blocks);
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Unknown block(s): ${unknown.join(', ')}. '
        'Valid blocks: ${appBlocks.keys.join(', ')}.',
      );
    }
    if (blocks.isEmpty) {
      throw const FormatException('At least one block is required.');
    }

    final appTitle = (json['appTitle'] as String?)?.trim();
    return VerticalSpec(
      name: name,
      appTitle: (appTitle == null || appTitle.isEmpty)
          ? 'GrowERP ${name[0].toUpperCase()}${name.substring(1)}'
          : appTitle,
      blocks: blocks,
    );
  }

  @override
  String toString() =>
      'name:      $name\n'
      'title:     $appTitle\n'
      'blocks:    ${blocks.join(', ')}';
}
