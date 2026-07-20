import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class RestRequestStatsDialog extends StatefulWidget {
  final Company company;
  const RestRequestStatsDialog({required this.company, super.key});

  @override
  RestRequestStatsDialogState createState() => RestRequestStatsDialogState();
}

class RestRequestStatsDialogState extends State<RestRequestStatsDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Map<String, int> _stats = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final restClient = context.read<RestClient>();
      final compResult = await restClient.getRestRequest(
        // hits are recorded against the owner party, not the company party:
        // for an owner company those differ (company 100001 → owner GROWERP)
        ownerPartyId: widget.company.ownerPartyId ?? widget.company.partyId,
        startDateTime: _startDate?.toIso8601String(),
        endDateTime: _endDate?.toIso8601String(),
        limit: 10000,
      );

      final Map<String, int> counts = {};
      for (var req in compResult.restRequests) {
        final name = req.restRequestName ?? 'Unknown';
        counts[name] = (counts[name] ?? 0) + 1;
      }

      // Sort by count descending
      final sortedEntries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final sortedCounts = Map.fromEntries(sortedEntries);

      setState(() {
        _stats = sortedCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('RestRequestStatsDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'REST Accesses for ${widget.company.name}',
        width: 600,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Period: ${_startDate?.toLocal().toString().split(' ')[0]} - ${_endDate?.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text('Change Period'),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(child: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))))
            else if (_stats.isEmpty)
              const Expanded(child: Center(child: Text('No accesses found for this period.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _stats.length,
                  itemBuilder: (context, index) {
                    final key = _stats.keys.elementAt(index);
                    final count = _stats[key];
                    return ListTile(
                      title: Text(key),
                      trailing: Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
