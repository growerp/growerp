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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import 'package:growerp_core/growerp_core.dart';

/// Topic the backend publishes on when the background demo data load ends,
/// see load#DemoDataAsync in PartyServices100.xml.
const String demoDataLoadTopic = 'DemoDataLoad';

/// Shown when login returned 'setupInProgress': the account is set up and
/// authenticated, but the demo data is still being created on a backend worker
/// thread. Waits for the [demoDataLoadTopic] notification and then lets the
/// AuthBloc promote the session to authenticated.
///
/// The wait is never allowed to be a dead end: a dropped socket or a backend
/// that never reports back would otherwise strand the user here, so after
/// [_patienceLimit] the dialog offers to continue anyway. Nothing is lost by
/// continuing, the rows simply keep appearing as they are created.
class SetupInProgressDialog extends StatefulWidget {
  final Authenticate authenticate;

  const SetupInProgressDialog({super.key, required this.authenticate});

  @override
  SetupInProgressDialogState createState() => SetupInProgressDialogState();
}

class SetupInProgressDialogState extends State<SetupInProgressDialog> {
  static const Duration _patienceLimit = Duration(minutes: 3);

  Timer? _patienceTimer;
  Timer? _pollTimer;
  bool _tookTooLong = false;
  bool _failed = false;
  bool _continued = false;

  @override
  void initState() {
    super.initState();
    // The socket is only connected once login returns, which is after this
    // bloc was created at startup, so it has not subscribed yet. This makes it
    // attach its listener now that there is a live connection.
    context.read<NotificationBloc>().add(const NotificationFetch());
    // The backend persists the message, so polling covers the cases the socket
    // cannot: not subscribed yet when the load finished, or dropped since.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<NotificationBloc>().add(const NotificationFetch());
    });
    _patienceTimer = Timer(_patienceLimit, () {
      if (mounted) setState(() => _tookTooLong = true);
    });
  }

  @override
  void dispose() {
    _patienceTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _continue() {
    // The notification can be delivered more than once, and the button stays on
    // screen while the bloc works: only the first call may promote the session.
    if (_continued) return;
    _continued = true;
    _pollTimer?.cancel();
    context.read<AuthBloc>().add(const AuthSetupCompleted());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;

    return BlocListener<NotificationBloc, NotificationState>(
      listenWhen: (previous, current) =>
          previous.notificationSeq != current.notificationSeq,
      listener: (context, state) {
        // A poll returns a list, not a single pushed message, so look for the
        // one topic this dialog waits on instead of assuming it is first.
        final notification = state.notifications
            .where((n) => n.topic == demoDataLoadTopic)
            .firstOrNull;
        if (notification == null) return;
        if (notification.message?['loaded'] == true) {
          _continue();
        } else {
          setState(() => _failed = true);
        }
      },
      child: Padding(
        key: const Key('setupInProgress'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.settingUpYourCompany,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!_failed) const LoadingIndicator(),
            if (!_failed) const SizedBox(height: 20),
            Text(
              _failed
                  ? localizations.demoDataFailed
                  : _tookTooLong
                  ? localizations.demoDataTakingLong
                  : localizations.demoDataLoading,
              textAlign: TextAlign.center,
            ),
            if (_failed || _tookTooLong) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                key: const Key('continueWithoutDemoData'),
                onPressed: _continue,
                child: Text(localizations.continueButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
