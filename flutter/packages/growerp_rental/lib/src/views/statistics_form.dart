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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

/// The three numbers a date-range rental business is run on: occupancy, ADR
/// (average daily rate) and RevPAR (revenue per available unit) over a chosen
/// period. Shared by hotel (rooms) and rental (equipment); the asset class the
/// numbers are computed over follows the hosting app's applicationId.
class StatisticsForm extends StatefulWidget {
  const StatisticsForm({super.key});

  @override
  State<StatisticsForm> createState() => _StatisticsFormState();
}

class _StatisticsFormState extends State<StatisticsForm> {
  late RestClient _restClient;
  late bool _isHotel;
  late String _unitNoun; // 'Room' for hotel, 'Equipment' otherwise
  final _dateFormat = DateFormat('yyyy-MM-dd');
  HotelStatistics? _stats;
  bool _loading = true;
  String? _error;
  late DateTime _fromDate;
  late DateTime _thruDate;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<RestClient>();
    _isHotel = context.read<String>() == 'AppHotel';
    _unitNoun = _isHotel ? 'Room' : 'Equipment';
    _thruDate = CustomizableDateTime.current;
    _fromDate = _thruDate.subtract(const Duration(days: 30));
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final stats = await _restClient.getHotelStatistics(
        fromDate: _dateFormat.format(_fromDate),
        thruDate: _dateFormat.format(_thruDate),
        assetClassId: _isHotel ? 'AsClsRoom' : 'AsClsEquipment',
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _thruDate,
      firstDate: DateTime(CustomizableDateTime.current.year - 3),
      lastDate: DateTime(CustomizableDateTime.current.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (!_thruDate.isAfter(_fromDate)) {
          _thruDate = _fromDate.add(const Duration(days: 1));
        }
      } else {
        _thruDate = picked;
      }
    });
    await _fetch();
  }

  Widget _tile(String label, String value, Key key) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            key: key,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final unit = _unitNoun.toLowerCase();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('refresh'),
        onPressed: _fetch,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
      body: ListView(
        key: const Key('listView'),
        padding: const EdgeInsets.all(10),
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('statFromDate'),
                  onTap: () => _pickDate(isFrom: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'From'),
                    child: Text(_dateFormat.format(_fromDate)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  key: const Key('statThruDate'),
                  onTap: () => _pickDate(isFrom: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Thru'),
                    child: Text(_dateFormat.format(_thruDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const LoadingIndicator()
          else if (_error != null)
            Text('Error: $_error', key: const Key('statError'))
          else if (stats != null) ...[
            _tile(
              'Occupancy',
              '${stats.occupancyPercent ?? 0}%',
              const Key('occupancyPercent'),
            ),
            _tile('ADR (average daily rate)', '${stats.adr ?? 0}',
                const Key('adr')),
            _tile('RevPAR (revenue per available $unit)',
                '${stats.revPar ?? 0}', const Key('revPar')),
            _tile('$_unitNoun revenue', '${stats.roomRevenue ?? 0}',
                const Key('roomRevenue')),
            _tile(
              '$_unitNoun days sold / available',
              '${stats.occupiedRoomNights} / ${stats.availableRoomNights}',
              const Key('roomNights'),
            ),
            _tile('${_unitNoun}s', '${stats.totalRooms}',
                const Key('totalRooms')),
          ],
        ],
      ),
    );
  }
}
