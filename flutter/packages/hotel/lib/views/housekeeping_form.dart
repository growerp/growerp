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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Housekeeping board: every room with its occupancy for today and a
/// clean/dirty status the housekeeper flips as rooms are serviced.
class HousekeepingForm extends StatefulWidget {
  const HousekeepingForm({super.key});

  @override
  State<HousekeepingForm> createState() => _HousekeepingFormState();
}

class _HousekeepingFormState extends State<HousekeepingForm> {
  late RestClient _restClient;
  List<HotelRoom> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<RestClient>();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await _restClient.getHousekeeping(limit: 200);
      if (!mounted) return;
      setState(() {
        _rooms = result.rooms;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggle(HotelRoom room) async {
    final newStatus = room.hkStatusId == 'Clean' ? 'Dirty' : 'Clean';
    try {
      await _restClient.updateHousekeeping(
        assetId: room.assetId,
        hkStatusId: newStatus,
      );
      if (!mounted) return;
      setState(() {
        _rooms = _rooms
            .map(
              (r) => r.assetId == room.assetId
                  ? r.copyWith(hkStatusId: newStatus)
                  : r,
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      HelperFunctions.showMessage(context, '$e', Colors.red);
    }
  }

  /// end of a housekeeping round: every room clean again
  Future<void> _allClean() async {
    try {
      await _restClient.resetHousekeeping();
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      HelperFunctions.showMessage(context, '$e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();
    if (_error != null) {
      return Center(child: Text('Error: $_error', key: const Key('hkError')));
    }
    final dirtyCount = _rooms.where((r) => r.hkStatusId != 'Clean').length;
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            key: const Key('allClean'),
            heroTag: 'allClean',
            onPressed: dirtyCount == 0 ? null : _allClean,
            tooltip: 'All rooms clean',
            child: const Icon(Icons.done_all),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            key: const Key('refresh'),
            heroTag: 'refresh',
            onPressed: _fetch,
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Rooms: ${_rooms.length}   To clean: $dirtyCount',
              key: const Key('hkSummary'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: StyledDataTable(
              columns: const [
                StyledColumn(header: 'Room', flex: 2),
                StyledColumn(header: 'Type', flex: 2),
                StyledColumn(header: 'Occupied', flex: 1),
                StyledColumn(header: 'Status', flex: 2),
              ],
              rows: _rooms.indexed.map((entry) {
                final index = entry.$1;
                final room = entry.$2;
                final isClean = room.hkStatusId == 'Clean';
                return <Widget>[
                  Text(room.assetName ?? '', key: Key('hkRoom$index')),
                  Text(room.productName ?? ''),
                  Text(
                    room.occupied ? 'yes' : 'no',
                    key: Key('hkOccupied$index'),
                  ),
                  TextButton(
                    key: Key('hkToggle$index'),
                    onPressed: () => _toggle(room),
                    child: Text(
                      room.hkStatusId,
                      key: Key('hkStatus$index'),
                      style: TextStyle(
                        color: isClean ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
