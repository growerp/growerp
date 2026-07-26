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

import 'dart:io';
import 'package:logger/logger.dart';

/// Registers a package in the pub workspace at flutter/pubspec.yaml.
///
/// Adds [relPath] (e.g. 'packages/bakery' or 'packages/growerp_todo') to both
/// the top-level `workspace:` list and the `melos: packages:` list.
/// Idempotent: entries already present are left untouched.
///
/// Returns true when registration succeeded (or was already done).
bool addPackageToWorkspace(
  String growerpPath,
  String relPath,
  Logger logger,
) {
  final pubspecPath = '$growerpPath/flutter/pubspec.yaml';
  final pubspecFile = File(pubspecPath);

  if (!pubspecFile.existsSync()) {
    logger.e('Workspace pubspec not found: $pubspecPath');
    return false;
  }

  final lines = pubspecFile.readAsStringSync().split('\n');

  final addedWorkspace = _insertEntry(
    lines,
    sectionMatch: (line) => line.trim() == 'workspace:',
    entry: '  - $relPath',
    entryPrefix: '  - ',
    alphabetical: true,
  );
  final addedMelos = _insertEntry(
    lines,
    sectionMatch: (line) => line.trim() == 'packages:' && line.startsWith('  '),
    entry: '    - $relPath',
    entryPrefix: '    - ',
    alphabetical: false,
  );

  if (addedWorkspace == null || addedMelos == null) {
    logger.e(
      'Could not find workspace/melos packages lists in $pubspecPath - '
      'please add "$relPath" manually',
    );
    return false;
  }

  if (!addedWorkspace && !addedMelos) {
    logger.i('  ✓ $relPath already registered in workspace');
    return true;
  }

  pubspecFile.writeAsStringSync(lines.join('\n'));
  logger.i('  ✓ Registered $relPath in flutter/pubspec.yaml');
  return true;
}

/// Inserts [entry] into the list following the first line matching
/// [sectionMatch]. Returns true when inserted, false when already present,
/// null when the section was not found.
bool? _insertEntry(
  List<String> lines, {
  required bool Function(String) sectionMatch,
  required String entry,
  required String entryPrefix,
  required bool alphabetical,
}) {
  int sectionIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (sectionMatch(lines[i])) {
      sectionIndex = i;
      break;
    }
  }
  if (sectionIndex == -1) return null;

  // Collect the contiguous list entries following the section header.
  int end = sectionIndex + 1;
  while (end < lines.length && lines[end].startsWith(entryPrefix)) {
    if (lines[end] == entry) return false; // already registered
    end++;
  }
  if (end == sectionIndex + 1) return null; // empty/unrecognized list

  int insertIndex = end;
  if (alphabetical) {
    for (int i = sectionIndex + 1; i < end; i++) {
      if (lines[i].compareTo(entry) > 0) {
        insertIndex = i;
        break;
      }
    }
  }
  lines.insert(insertIndex, entry);
  return true;
}
