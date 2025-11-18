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

import '../bloc/credibility_bloc.dart';
import '../bloc/credibility_event.dart';
import '../bloc/credibility_state.dart';
import 'credibility_info_detail_screen.dart';

class CredibilityInfoListScreen extends StatefulWidget {
  final String landingPageId;

  const CredibilityInfoListScreen({
    super.key,
    required this.landingPageId,
  });

  @override
  CredibilityInfoListScreenState createState() =>
      CredibilityInfoListScreenState();
}

class CredibilityInfoListScreenState extends State<CredibilityInfoListScreen> {
  late CredibilityBloc _credibilityBloc;

  @override
  void initState() {
    super.initState();
    _credibilityBloc = context.read<CredibilityBloc>()
      ..add(CredibilityLoad(landingPageId: widget.landingPageId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        key: const Key('addCredibility'),
        onPressed: () async {
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return BlocProvider.value(
                value: _credibilityBloc,
                child: CredibilityInfoDetailScreen(
                  landingPageId: widget.landingPageId,
                  credibilityInfo: const CredibilityInfo(),
                ),
              );
            },
          );
        },
        tooltip: 'Add Credibility Info',
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<CredibilityBloc, CredibilityState>(
        listener: (context, state) {
          if (state.status == CredibilityStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'Error loading credibility',
              Colors.red,
            );
          }
          if (state.status == CredibilityStatus.success &&
              (state.message ?? '').isNotEmpty) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        },
        builder: (context, state) {
          if (state.status == CredibilityStatus.loading) {
            return const LoadingIndicator();
          }

          if (state.credibilityElements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No credibility information yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add credibility info',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.credibilityElements.length,
            itemBuilder: (context, index) {
              final credibility = state.credibilityElements[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: credibility.creatorImageUrl != null
                      ? CircleAvatar(
                          backgroundImage:
                              NetworkImage(credibility.creatorImageUrl!),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                  title: Text(credibility.pseudoId ?? 'Credibility Info'),
                  subtitle: Text(
                    credibility.creatorBio ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (credibility.statistics?.isNotEmpty ?? false)
                        Chip(
                          label: Text(
                            '${credibility.statistics!.length} stats',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Credibility Info'),
                                content: const Text(
                                  'Are you sure you want to delete this credibility information?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            _credibilityBloc.add(
                              CredibilityInfoDelete(
                                landingPageId: widget.landingPageId,
                                credibilityInfoId:
                                    credibility.credibilityInfoId ?? '',
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    await showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return BlocProvider.value(
                          value: _credibilityBloc,
                          child: CredibilityInfoDetailScreen(
                            landingPageId: widget.landingPageId,
                            credibilityInfo: credibility,
                          ),
                        );
                      },
                    );
                    // Reload credibility data after dialog closes to show any new statistics
                    _credibilityBloc.add(
                      CredibilityLoad(landingPageId: widget.landingPageId),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
