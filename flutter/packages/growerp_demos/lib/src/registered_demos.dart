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
