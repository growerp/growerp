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

import 'package:growerp_core/growerp_core.dart';

/// Fetches a record by id and shows its entity dialog once loaded.
///
/// Generalises the `ShowFinDocDialog` / `ShowCompanyDialog` fetch-then-delegate
/// pattern so the AI chat can open any entity's edit dialog by id:
/// while [fetch] is in flight a loading dialog is shown; when it resolves,
/// [onLoaded] builds the entity dialog (which returns its own [Dialog]).
///
/// On not-found / error the dialog does NOT linger as an empty screen: it closes
/// itself and reports the message via [messageSink] (the AI chat registers this
/// so the failure appears as chat text). When no sink is registered it falls back
/// to a small [AlertDialog].
class AsyncRecordDialog<T> extends StatelessWidget {
  /// Loads the record (e.g. via `context.read<RestClient>()`); returns null when
  /// not found.
  final Future<T?> Function(BuildContext) fetch;

  /// Builds the entity dialog for the loaded record.
  final Widget Function(T) onLoaded;

  /// Optional sink for not-found/error messages. The AI chat sets this so a
  /// failed lookup is shown as a chat message instead of a popped screen.
  static void Function(String message)? messageSink;

  const AsyncRecordDialog({
    super.key,
    required this.fetch,
    required this.onLoaded,
  });

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<T?>(
      future: fetch(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Dialog(
            child: SizedBox(height: 200, child: LoadingIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final message = snapshot.hasError
              ? 'Could not load record: ${snapshot.error}'
              : 'Record not found';
          final sink = messageSink;
          if (sink != null) {
            // Close this dialog and report the failure as chat text.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final nav = Navigator.of(context);
              if (nav.canPop()) nav.pop();
              sink(message);
            });
            return const SizedBox.shrink();
          }
          return AlertDialog(
            content: Text(message, style: const TextStyle(color: Colors.red)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(CoreLocalizations.of(context)!.close),
              ),
            ],
          );
        }
        return onLoaded(snapshot.data as T);
      },
    );
  }
}
