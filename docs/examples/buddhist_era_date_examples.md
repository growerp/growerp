/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

/// Example: Buddhist Era Date Formatting in GrowERP
///
/// This file demonstrates how to use localized date formatting with
/// automatic Buddhist Era support for Thai users.

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

// ============================================================================
// Example 1: Simple List Display
// ============================================================================

class OrderListExample extends StatelessWidget {
  final List<FinDoc> orders;

  const OrderListExample({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          title: Text(order.pseudoId ?? 'Order ${order.id()}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ CORRECT: Use localized date for display
              Text('Placed: ${order.placedDate.toLocalizedDateOnly(context)}'),
              Text(
                'Created: ${order.creationDate.toLocalizedShortDate(context)}',
              ),
            ],
          ),
          trailing: Text(
            order.grandTotal?.currency() ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Example 2: Table/DataTable Display
// ============================================================================

class SubscriptionTableExample extends StatelessWidget {
  final List<Subscription> subscriptions;

  const SubscriptionTableExample({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Subscriber')),
        DataColumn(label: Text('From Date')),
        DataColumn(label: Text('Thru Date')),
      ],
      rows: subscriptions.map((sub) {
        return DataRow(
          cells: [
            DataCell(Text(sub.pseudoId ?? '')),
            DataCell(Text(sub.subscriber?.name ?? '')),
            // ✅ CORRECT: Localized dates in table cells
            DataCell(Text(sub.fromDate.toLocalizedDateOnly(context))),
            DataCell(Text(sub.thruDate.toLocalizedDateOnly(context))),
          ],
        );
      }).toList(),
    );
  }
}

// ============================================================================
// Example 3: Date Picker with Localized Display
// ============================================================================

class ReservationFormExample extends StatefulWidget {
  const ReservationFormExample({super.key});

  @override
  State<ReservationFormExample> createState() => _ReservationFormExampleState();
}

class _ReservationFormExampleState extends State<ReservationFormExample> {
  DateTime? _fromDate;
  DateTime? _thruDate;

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectThruDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _thruDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _thruDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // From Date Picker
        ListTile(
          title: const Text('From Date'),
          // ✅ CORRECT: Display picked date with localization
          subtitle: Text(
            _fromDate != null
                ? _fromDate.toLocalizedDateOnly(context)
                : 'Select date',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectFromDate,
        ),

        // Thru Date Picker
        ListTile(
          title: const Text('Thru Date'),
          // ✅ CORRECT: Display picked date with localization
          subtitle: Text(
            _thruDate != null
                ? _thruDate.toLocalizedDateOnly(context)
                : 'Select date',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectThruDate,
        ),

        // Submit Button
        ElevatedButton(
          onPressed: _fromDate != null && _thruDate != null
              ? () {
                  // ✅ CORRECT: Send Gregorian dates to backend
                  // The DateTime objects are already in Gregorian
                  _submitReservation(_fromDate!, _thruDate!);
                }
              : null,
          child: const Text('Create Reservation'),
        ),
      ],
    );
  }

  void _submitReservation(DateTime from, DateTime thru) {
    // Backend receives Gregorian dates (e.g., 2025-10-04)
    // even if displayed as Buddhist Era to Thai users (2568-10-04)
    debugPrint('Submitting: from=${from.toIso8601String()}');
    debugPrint('Submitting: thru=${thru.toIso8601String()}');
  }
}

// ============================================================================
// Example 4: Conditional Formatting Based on Locale
// ============================================================================

class LocaleAwareDisplayExample extends StatelessWidget {
  final DateTime eventDate;

  const LocaleAwareDisplayExample({super.key, required this.eventDate});

  @override
  Widget build(BuildContext context) {
    final isThaiLocale = LocalizedDateHelper.isThaiLocale(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Display with appropriate format for locale
            Text(
              eventDate.toLocalizedString(
                context,
                format: isThaiLocale ? 'dd/MM/yyyy' : 'MM/dd/yyyy',
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              isThaiLocale ? 'พุทธศักราช (Buddhist Era)' : 'Gregorian Calendar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Example 5: Custom Table Widget with Localized Dates
// ============================================================================

class CustomTableRowExample {
  static TableData buildOrderRow(
    BuildContext context,
    FinDoc order,
    int index,
  ) {
    return TableData(
      rowHeight: 40,
      rowContent: [
        TableRowContent(
          name: 'Order #',
          width: 15,
          value: Text(order.pseudoId ?? '', key: Key('order$index')),
        ),
        TableRowContent(
          name: 'Customer',
          width: 30,
          value: Text(
            order.otherCompany?.name ?? '',
            key: Key('customer$index'),
          ),
        ),
        // ✅ CORRECT: Localized date in table
        TableRowContent(
          name: 'Date',
          width: 20,
          value: Text(
            order.placedDate.toLocalizedDateOnly(context),
            key: Key('date$index'),
          ),
        ),
        TableRowContent(
          name: 'Total',
          width: 20,
          value: Text(
            order.grandTotal?.currency() ?? '',
            key: Key('total$index'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Example 6: Search/Filter Display
// ============================================================================

class SearchResultsExample extends StatelessWidget {
  final List<FinDoc> searchResults;
  final DateTime? filterFromDate;
  final DateTime? filterThruDate;

  const SearchResultsExample({
    super.key,
    required this.searchResults,
    this.filterFromDate,
    this.filterThruDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show active filters with localized dates
        if (filterFromDate != null || filterThruDate != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Filtering: '
              '${filterFromDate != null ? "From ${filterFromDate.toLocalizedShortDate(context)}" : ""}'
              '${filterFromDate != null && filterThruDate != null ? " " : ""}'
              '${filterThruDate != null ? "To ${filterThruDate.toLocalizedShortDate(context)}" : ""}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),

        // Results list
        Expanded(
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final doc = searchResults[index];
              return ListTile(
                title: Text(doc.pseudoId ?? 'Document ${doc.id()}'),
                // ✅ CORRECT: Localized dates in results
                subtitle: Text(doc.creationDate.toLocalizedDateTime(context)),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Example 7: Form Field with Date Display
// ============================================================================

class DateDisplayFieldExample extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const DateDisplayFieldExample({
    super.key,
    required this.label,
    this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        // ✅ CORRECT: Show localized date or placeholder
        child: Text(
          date?.toLocalizedDateOnly(context) ?? 'Select date',
          style: TextStyle(
            color: date != null ? null : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COUNTER-EXAMPLES: What NOT to do
// ============================================================================

// ❌ WRONG: Don't use in tests
class WrongTestExample {
  void testOrderDates() {
    // final order = FinDoc(...);
    //
    // // WRONG! Tests should use dateOnly()
    // expect(
    //   order.placedDate.toLocalizedDateOnly(context),
    //   '2568-10-04',  // Buddhist Era - wrong for tests!
    // );
    //
    // // CORRECT:
    // expect(
    //   order.placedDate.dateOnly(),
    //   '2025-10-04',  // Gregorian - correct for tests!
    // );
  }
}

// ❌ WRONG: Don't hard-code Buddhist Era dates
class WrongHardCodedExample extends StatelessWidget {
  const WrongHardCodedExample({super.key});

  @override
  Widget build(BuildContext context) {
    // WRONG! Don't hard-code BE years
    return const Text('Created: 2568-10-04');

    // CORRECT: Use dynamic date with localization
    // DateTime createdDate = ...;
    // return Text('Created: ${createdDate.toLocalizedDateOnly(context)}');
  }
}

// ❌ WRONG: Don't send BE dates to backend
class WrongBackendExample {
  void createOrder(DateTime orderDate) {
    // WRONG! Don't convert to BE before sending
    // final beYear = orderDate.year + 543;
    // final beDate = DateTime(beYear, orderDate.month, orderDate.day);
    // api.createOrder(date: beDate);  // Backend gets wrong year!

    // CORRECT: Send Gregorian date (DateTime objects are always Gregorian)
    // api.createOrder(date: orderDate);  // Correct!
  }
}
