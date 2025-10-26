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

/// Admin interface for managing landing pages
class LandingPageAdmin extends StatefulWidget {
  const LandingPageAdmin({super.key});

  @override
  State<LandingPageAdmin> createState() => _LandingPageAdminState();
}

class _LandingPageAdminState extends State<LandingPageAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Page Admin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Landing Page Administration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Manage landing pages, content, and assessments.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            // TODO: Add list of landing pages with CRUD operations
            Text(
              'Landing page management coming soon...',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new landing page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create new landing page - coming soon!'),
            ),
          );
        },
        tooltip: 'Create Landing Page',
        child: const Icon(Icons.add),
      ),
    );
  }
}
