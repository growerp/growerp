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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/credibility_bloc.dart';
import '../bloc/credibility_event.dart';
import '../bloc/credibility_state.dart';

class CredibilityInfoDetailScreen extends StatefulWidget {
  final String landingPageId;
  final CredibilityInfo credibilityInfo;

  const CredibilityInfoDetailScreen({
    super.key,
    required this.landingPageId,
    required this.credibilityInfo,
  });

  @override
  CredibilityInfoDetailScreenState createState() =>
      CredibilityInfoDetailScreenState();
}

class CredibilityInfoDetailScreenState
    extends State<CredibilityInfoDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _backgroundController;
  late TextEditingController _imageUrlController;
  late List<Map<String, dynamic>> _statistics;

  @override
  void initState() {
    super.initState();
    _bioController =
        TextEditingController(text: widget.credibilityInfo.creatorBio ?? '');
    _backgroundController = TextEditingController(
        text: widget.credibilityInfo.backgroundText ?? '');
    _imageUrlController = TextEditingController(
        text: widget.credibilityInfo.creatorImageUrl ?? '');

    // Initialize statistics list with existing data
    _statistics = (widget.credibilityInfo.statistics ?? [])
        .map((stat) => {
              'id': stat.credibilityStatisticId,
              'controller': TextEditingController(text: stat.statistic ?? ''),
              'sequence': stat.sequence ?? 0,
            })
        .toList();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _backgroundController.dispose();
    _imageUrlController.dispose();
    for (var stat in _statistics) {
      (stat['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addStatistic() {
    setState(() {
      _statistics.add({
        'id': null,
        'controller': TextEditingController(),
        'sequence': _statistics.length + 1,
      });
    });
  }

  void _removeStatistic(int index) {
    setState(() {
      ((_statistics[index]['controller']) as TextEditingController).dispose();
      _statistics.removeAt(index);
      // Update sequences
      for (int i = 0; i < _statistics.length; i++) {
        _statistics[i]['sequence'] = i + 1;
      }
    });
  }

  void _saveCredibility() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isNew = widget.credibilityInfo.credibilityInfoId == null;
    final credibilityBloc = context.read<CredibilityBloc>();

    if (isNew) {
      // For new credibility info, serialize statistics with the creation
      final statsJsonList = _statistics.where((stat) {
        final controller = stat['controller'] as TextEditingController;
        return controller.text.isNotEmpty;
      }).map((stat) {
        final controller = stat['controller'] as TextEditingController;
        return {
          'statistic': controller.text,
          'sequence': stat['sequence'] ?? 1,
        };
      }).toList();
      final statsJson =
          statsJsonList.isNotEmpty ? jsonEncode(statsJsonList) : null;

      credibilityBloc.add(
        CredibilityInfoCreate(
          landingPageId: widget.landingPageId,
          infoTitle: _bioController.text,
          infoDescription: _backgroundController.text,
          infoIconName: _imageUrlController.text,
          statisticsJson: statsJson,
        ),
      );
    } else {
      // For updates, serialize ALL current statistics (replaces all existing)
      final statsJsonList = _statistics.where((stat) {
        final controller = stat['controller'] as TextEditingController;
        return controller.text.isNotEmpty;
      }).map((stat) {
        final controller = stat['controller'] as TextEditingController;
        return {
          'statistic': controller.text,
          'sequence': stat['sequence'] ?? 1,
        };
      }).toList();
      // Always send statistics JSON (empty array if no statistics) to signal deletion
      final statsJson = jsonEncode(statsJsonList);

      // Update credibility info with statistics atomically
      credibilityBloc.add(
        CredibilityInfoUpdate(
          landingPageId: widget.landingPageId,
          credibilityInfoId: widget.credibilityInfo.credibilityInfoId!,
          pseudoId: widget.credibilityInfo.pseudoId,
          infoTitle: _bioController.text,
          infoDescription: _backgroundController.text,
          infoIconName: _imageUrlController.text,
          statisticsJson: statsJson,
        ),
      );
    }

    // Pop immediately after dispatching the event
    // The credibility list will reload in the background
    if (mounted) {
      Navigator.of(context, rootNavigator: false).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.credibilityInfo.credibilityInfoId == null;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: popUp(
        context: context,
        title:
            'Credibility Info${isNew ? ' #New' : ' #${widget.credibilityInfo.pseudoId}'}',
        width: 700,
        height: 650,
        child: BlocConsumer<CredibilityBloc, CredibilityState>(
          listener: (context, state) {
            if (state.status == CredibilityStatus.failure) {
              HelperFunctions.showMessage(
                context,
                state.message ?? 'Error',
                Colors.red,
              );
            }
          },
          builder: (context, state) {
            if (state.status == CredibilityStatus.loading) {
              return const LoadingIndicator();
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                key: const Key('credibilityInfoScrollView'),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Creator Info Section
                      const Text(
                        'Creator Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('creatorBio'),
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Creator Bio *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter creator bio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('backgroundText'),
                        controller: _backgroundController,
                        decoration: const InputDecoration(
                          labelText: 'Background/Experience',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('creatorImageUrl'),
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Creator Image URL',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/photo.jpg',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Statistics Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            key: const Key('addStatistic'),
                            icon: const Icon(Icons.add_circle),
                            color: Colors.blue,
                            onPressed: _addStatistic,
                            tooltip: 'Add Statistic',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_statistics.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No statistics yet. Click + to add.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._statistics.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> stat = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: Key('statistic$index'),
                                    controller: stat['controller']
                                        as TextEditingController,
                                    decoration: InputDecoration(
                                      labelText: 'Statistic ${index + 1}',
                                      border: const OutlineInputBorder(),
                                      hintText: 'e.g., 100+ customers',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter statistic text';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeStatistic(index),
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(context, rootNavigator: false)
                                      .pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              key: const Key('saveCredibility'),
                              onPressed: _saveCredibility,
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
