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

/// Describes a runnable demo that appears in the demo list.
class DemoEntry {
  final String title;
  final String description;
  final IconData icon;
  final int totalPhases;
  final Future<int> Function(String ownerPartyId) getProgress;
  final Future<void> Function(String ownerPartyId) resetProgress;
  final Widget Function() builder;

  const DemoEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.totalPhases,
    required this.getProgress,
    required this.resetProgress,
    required this.builder,
  });
}
