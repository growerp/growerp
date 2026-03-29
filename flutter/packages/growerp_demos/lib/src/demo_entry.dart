/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
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
