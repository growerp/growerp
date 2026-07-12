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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

/// Manage bookable appointment slots; visitors book them on the public
/// /booking page of the generated website.
class AppointmentSlotList extends StatefulWidget {
  const AppointmentSlotList({super.key});

  @override
  AppointmentSlotListState createState() => AppointmentSlotListState();
}

class AppointmentSlotListState extends State<AppointmentSlotList> {
  List<AppointmentSlot> slots = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<RestClient>().getAppointmentSlot(
        limit: 100,
      );
      if (mounted) setState(() => slots = result.appointmentSlots);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    try {
      await context.read<RestClient>().createAppointmentSlot(
        appointmentSlot: AppointmentSlot(
          startDateTime: start,
          endDateTime: start.add(const Duration(minutes: 30)),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(context, 'Create failed: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteSlot(AppointmentSlot slot) async {
    final shouldDelete = await confirmDialog(
      context,
      'Delete this slot?',
      'This cannot be undone!',
    );
    if (shouldDelete != true || !mounted) return;
    try {
      await context.read<RestClient>().deleteAppointmentSlot(
        appointmentSlot: slot,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(context, 'Delete failed: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && slots.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Bookable time slots — visitors book them on the /booking '
                'page of your website (30 minutes each).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: slots.isEmpty
                  ? const Center(child: Text('No slots yet — add some below'))
                  : ListView.builder(
                      key: const Key('appointmentSlotList'),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final start = slot.startDateTime
                            ?.toLocal()
                            .toString()
                            .substring(0, 16);
                        return ListTile(
                          key: Key('slotItem$index'),
                          leading: Icon(
                            slot.status == 'BOOKED'
                                ? Icons.event_busy
                                : Icons.event_available,
                            color: slot.status == 'BOOKED'
                                ? Colors.orange
                                : Colors.green,
                          ),
                          title: Text(start ?? ''),
                          subtitle: Text(slot.status),
                          trailing: slot.status == 'AVAILABLE'
                              ? IconButton(
                                  key: Key('slotDelete$index'),
                                  icon: const Icon(Icons.delete_forever),
                                  onPressed: () => _deleteSlot(slot),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 50,
          child: FloatingActionButton(
            key: const Key('addNew'),
            onPressed: _addSlot,
            tooltip: 'Add slot',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
