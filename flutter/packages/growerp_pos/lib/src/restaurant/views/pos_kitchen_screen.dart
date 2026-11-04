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

import '../../../l10n/generated/pos_localizations.dart';
import '../blocs/pos_kitchen_bloc.dart';
import 'pos_live_refresh.dart';

/// The tickets the kitchen is working on, the oldest first. A tap moves a line
/// on: to ready, then to served.
class PosKitchenScreen extends StatefulWidget {
  const PosKitchenScreen({super.key});

  @override
  PosKitchenScreenState createState() => PosKitchenScreenState();
}

class PosKitchenScreenState extends State<PosKitchenScreen>
    with PosLiveRefresh {
  late PosKitchenBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<PosKitchenBloc>()..add(const PosKitchenFetch());
    startRefresh();
  }

  @override
  void onRefresh() => _bloc.add(const PosKitchenFetch());

  @override
  void dispose() {
    stopRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return BlocConsumer<PosKitchenBloc, PosKitchenState>(
      listener: (context, state) {
        if (state.status == PosKitchenStatus.failure) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == PosKitchenStatus.initial) {
          return const Center(child: LoadingIndicator());
        }
        if (state.tickets.isEmpty) {
          return Center(
            key: const Key('posKitchenEmpty'),
            child: Text(localizations.kitchenEmpty),
          );
        }
        return GridView.builder(
          key: const Key('PosKitchenScreen'),
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: state.tickets.length,
          itemBuilder: (context, index) {
            final ticket = state.tickets[index];
            final minutes = ticket.sentDate == null
                ? 0
                : DateTime.now().difference(ticket.sentDate!).inMinutes;
            return Card(
              key: Key('posTicket$index'),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text(
                      ticket.tableName ?? localizations.bar,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    trailing: Text(
                      "$minutes'",
                      style: TextStyle(
                        color: minutes >= 15 ? Colors.red : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final (lineIndex, line) in ticket.lines.indexed)
                          ListTile(
                            key: Key('posTicketLine${index}_$lineIndex'),
                            dense: true,
                            leading: Icon(
                              line.kitchenStatus == 'Ready'
                                  ? Icons.notifications_active
                                  : Icons.soup_kitchen_outlined,
                              color: line.kitchenStatus == 'Ready'
                                  ? Colors.green
                                  : null,
                            ),
                            title: Text(
                              '${line.quantity} x ${line.description ?? ''}',
                            ),
                            subtitle: line.note == null || line.note!.isEmpty
                                ? null
                                : Text(line.note!),
                            onTap: () => _bloc.add(PosKitchenBump(line)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
