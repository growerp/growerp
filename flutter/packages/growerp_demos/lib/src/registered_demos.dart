/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';

import 'catalog_swag/catalog_swag_demo_runner.dart';
import 'catalog_swag/catalog_swag_demo_service.dart';
import 'demo_entry.dart';
import 'liner/liner_demo_runner.dart';
import 'liner/liner_demo_service.dart';
import 'mfg/mfg_demo_runner.dart';
import 'mfg/mfg_demo_service.dart';

/// All demos available in the growerp_demos package.
/// Add new demos here to have them appear in [DemoListScreen].
final List<DemoEntry> registeredDemos = [
  DemoEntry(
    title: 'Catalog & Manufacturing Demo',
    description:
        'End-to-end lifecycle with SWAG products: create a marketing '
        'package (cap, mug, USB drive), sell kits via a sales order, '
        'auto-create a work order, purchase and receive components, '
        'assemble the kits, ship to the customer, and review GL transactions.',
    icon: Icons.precision_manufacturing,
    totalPhases: 9,
    getProgress: catalogSwagProgress.getCurrentStep,
    resetProgress: catalogSwagProgress.reset,
    builder: () => const CatalogSwagDemoRunner(),
  ),
  DemoEntry(
    title: 'Manufacturing Demo',
    description:
        'End-to-end Widget Assembly lifecycle: define a BOM and production '
        'routing, create a sales order, auto-create a work order with routing '
        'steps, purchase and receive components, run production, ship to '
        'the customer, and review GL transactions.',
    icon: Icons.build,
    totalPhases: 10,
    getProgress: mfgDemoProgress.getCurrentStep,
    resetProgress: mfgDemoProgress.reset,
    builder: () => const MfgDemoRunner(),
  ),
  DemoEntry(
    title: 'Liner Panel Manufacturing Demo',
    description:
        'Industry-specific liner panel lifecycle: configure liner types and '
        'routing, build a BOM for pond liner systems, create a sales order, '
        'add liner panel specifications to the work order, purchase roll '
        'stock, produce liner systems, ship, and review accounting.',
    icon: Icons.layers,
    totalPhases: 10,
    getProgress: linerDemoProgress.getCurrentStep,
    resetProgress: linerDemoProgress.reset,
    builder: () => const LinerDemoRunner(),
  ),
];
