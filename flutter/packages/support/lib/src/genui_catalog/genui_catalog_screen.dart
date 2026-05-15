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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class GenUiCatalogScreen extends StatelessWidget {
  const GenUiCatalogScreen({super.key});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GenUi Catalog')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('WelcomeCard'),
          WelcomeCard(
            greeting: 'Welcome to GrowERP!',
            inputPrompt: 'Tell us about your business',
            hintText: 'e.g. retail store, consulting firm',
            onSubmit: (text) async =>
                _showSnack(context, 'Submitted: $text'),
          ),
          const SizedBox(height: 24),
          _sectionHeader('OptionsCard'),
          OptionsCard(
            question: 'What best describes your business?',
            options: const ['Products', 'Services', 'Both'],
            multiSelect: false,
            onSubmit: (text) async =>
                _showSnack(context, 'Selected: $text'),
          ),
          const SizedBox(height: 24),
          _sectionHeader('MenuPreviewCard'),
          MenuPreviewCard(
            headline: 'Your personalized menu',
            classificationId: 'AppAdmin',
            name: 'Demo Company',
            menuItems: const [
              {
                'title': 'Dashboard',
                'route': '/',
                'widgetName': 'AdminDashboard',
              },
              {
                'title': 'Inventory',
                'route': '/inventory',
                'widgetName': 'AssetList',
              },
              {
                'title': 'Sales Orders',
                'route': '/orders',
                'widgetName': 'SalesOrderList',
              },
            ],
            onSubmit: (text) async =>
                _showSnack(context, 'Feedback: $text'),
            onFinalize: (OnboardingMenuConfig config) async =>
                _showSnack(
                    context, 'Menu finalized: ${config.menuItems.length} items'),
          ),
          const SizedBox(height: 24),
          _sectionHeader('InvoiceEntryCard'),
          InvoiceEntryCard(
            headline: 'Please confirm this invoice',
            pseudoId: '10025',
            customerName: 'Acme Corp',
            status: 'In Preparation',
            description: 'May consulting engagement',
            items: const [
              {'description': 'Consulting services', 'quantity': 8, 'price': 150.00},
              {'description': 'Travel expenses', 'quantity': 1, 'price': 320.00},
              {'description': 'Software license', 'quantity': 3, 'price': 49.99},
            ],
            onSubmit: (text) async =>
                _showSnack(context, 'Invoice confirmed: $text'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      );
}
