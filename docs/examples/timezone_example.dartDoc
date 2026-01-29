// ignore_for_file: unused_import, undefined_class, undefined_identifier
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
// jsut a demo file to show how to use the timezone helper
// This file is not used in the actual application, but serves as an example
// of how to handle timezones in GrowERP applications.
// compile errors are expected, this is not a real application file
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

/// Example widget demonstrating proper timezone handling in GrowERP
///
/// This example shows:
/// 1. How to display dates from server (UTC) in local timezone
/// 2. How to handle form input and convert to UTC for server
/// 3. How to format dates consistently
/// 4. How to use TimeZoneHelper utilities
class TimezoneExampleWidget extends StatefulWidget {
  final ExampleModel? initialData;

  const TimezoneExampleWidget({super.key, this.initialData});

  @override
  State<TimezoneExampleWidget> createState() => _TimezoneExampleWidgetState();
}

class _TimezoneExampleWidgetState extends State<TimezoneExampleWidget> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timezone Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display current timezone info
            _buildTimezoneInfo(),
            const SizedBox(height: 20),

            // Example of displaying server dates in local time
            _buildServerDateDisplay(),
            const SizedBox(height: 20),

            // Form with proper timezone handling
            _buildDateForm(),
            const SizedBox(height: 20),

            // Examples of date formatting
            _buildFormattingExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneInfo() {
    final now = DateTime.now();
    final utcNow = now.toUtc();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Timezone Info:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Local time: ${TimeZoneHelper.formatLocalDateTime(now)}'),
            Text('UTC time: ${TimeZoneHelper.formatLocalDateTime(utcNow)}'),
            Text('Timezone offset: ${now.timeZoneOffset}'),
            Text('Timezone name: ${now.timeZoneName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildServerDateDisplay() {
    // Example: Server sends "2025-08-02T10:00:00Z" (UTC)
    // We want to display it in user's local timezone

    const serverDateString = "2025-08-02T10:00:00Z";
    final localDate = TimeZoneHelper.fromServerTime(serverDateString);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Date Display Example:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Server UTC time: $serverDateString'),
            Text(
              'Displayed locally: ${TimeZoneHelper.formatLocalDateTime(localDate)}',
            ),
            Text('Date only: ${TimeZoneHelper.formatLocalDate(localDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date Form Example:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Event date picker
              FormBuilderDateTimePicker(
                name: 'eventDate',
                // Convert server UTC time to local for display
                initialValue: widget.initialData?.eventDate?.toLocal(),
                inputType: InputType.date,
                format: DateFormat('yyyy/M/d'),
                decoration: const InputDecoration(
                  labelText: 'Event Date',
                  suffixIcon: Icon(Icons.calendar_today),
                  helperText: 'Date will be stored in UTC on server',
                ),
                validator: FormBuilderValidators.required(),
              ),

              // Event time picker
              FormBuilderDateTimePicker(
                name: 'eventTime',
                initialValue: widget.initialData?.eventDate?.toLocal(),
                inputType: InputType.time,
                format: DateFormat('HH:mm'),
                decoration: const InputDecoration(
                  labelText: 'Event Time',
                  suffixIcon: Icon(Icons.access_time),
                  helperText: 'Time in your local timezone',
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleFormSubmit,
                child: const Text('Save Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattingExamples() {
    final sampleDate = DateTime(2025, 8, 2, 14, 30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Formatting Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Default: ${TimeZoneHelper.formatLocalDate(sampleDate)}'),
            Text(
              'US format: ${TimeZoneHelper.formatLocalDate(sampleDate, format: 'MM/dd/yyyy')}',
            ),
            Text(
              'European: ${TimeZoneHelper.formatLocalDate(sampleDate, format: 'dd/MM/yyyy')}',
            ),
            Text(
              'With time: ${TimeZoneHelper.formatLocalDateTime(sampleDate)}',
            ),
            Text(
              'Full format: ${TimeZoneHelper.formatLocalDateTime(sampleDate, format: 'EEEE, MMMM d, yyyy HH:mm')}',
            ),
            const SizedBox(height: 8),
            Text('Extension usage: ${sampleDate.dateOnly()}'),
          ],
        ),
      ),
    );
  }

  void _handleFormSubmit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      // Get the local date/time from form
      final localEventDate = formData['eventDate'] as DateTime?;
      final localEventTime = formData['eventTime'] as DateTime?;

      // Combine date and time if both provided
      DateTime? combinedDateTime;
      if (localEventDate != null) {
        if (localEventTime != null) {
          combinedDateTime = DateTime(
            localEventDate.year,
            localEventDate.month,
            localEventDate.day,
            localEventTime.hour,
            localEventTime.minute,
          );
        } else {
          combinedDateTime = localEventDate;
        }
      }

      // Create model with UTC time for server
      final exampleModel = ExampleModel(
        id: widget.initialData?.id,
        title: 'Example Event',
        // Convert to UTC for server storage
        eventDate: combinedDateTime?.toServerTime(),
      );

      // Show what would be sent to server
      _showServerPayload(exampleModel);
    }
  }

  void _showServerPayload(ExampleModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Payload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is what gets sent to server:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Event Date UTC: ${model.eventDate?.toIso8601String() ?? 'null'}',
            ),
            const SizedBox(height: 8),
            const Text(
              'The DateTimeConverter automatically converts this to UTC ISO string for JSON.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Example model demonstrating timezone handling
@freezed
class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    String? id,
    String? title,
    @DateTimeConverter() DateTime? eventDate,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);
}

/// Example of how to use the timezone utilities in a list widget
class TimezoneListExample extends StatelessWidget {
  final List<ExampleModel> events;

  const TimezoneListExample({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          title: Text(event.title ?? 'Untitled Event'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display in local timezone
              Text(
                'Event: ${TimeZoneHelper.formatLocalDateTime(event.eventDate)}',
              ),
              Text(
                'Created: ${TimeZoneHelper.formatLocalDate(event.createdAt)}',
              ),
            ],
          ),
          trailing: _buildDateChip(event.eventDate),
        );
      },
    );
  }

  Widget _buildDateChip(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final isToday = TimeZoneHelper.isSameLocalDate(date, now);
    final isTomorrow = TimeZoneHelper.isSameLocalDate(
      date,
      now.add(const Duration(days: 1)),
    );

    String label;
    Color color;

    if (isToday) {
      label = 'Today';
      color = Colors.green;
    } else if (isTomorrow) {
      label = 'Tomorrow';
      color = Colors.orange;
    } else {
      label = TimeZoneHelper.formatLocalDate(date, format: 'MMM d');
      color = Colors.blue;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}
