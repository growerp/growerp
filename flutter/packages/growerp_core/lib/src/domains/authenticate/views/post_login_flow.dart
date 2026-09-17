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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:universal_io/io.dart';

import '../../../domains/domains.dart';

/// Shows the one-time welcome sequence (trial welcome + ERP assessment) of a new
/// tenant admin, on top of the dashboard.
///
/// It runs here and not from the login dialog: the login dialog lives on the
/// navigator of the splash router, and the moment the menu configuration of the
/// just authenticated user arrives that router is replaced by the app router.
/// Dialogs opened from there are then disposed without being popped, so the
/// welcome flashed by and registerAppUsed - which runs after the dialogs close -
/// never marked the app as used, bringing the welcome back on the next login.
class PostLoginFlow extends StatefulWidget {
  const PostLoginFlow({super.key, required this.child});

  final Widget child;

  @override
  State<PostLoginFlow> createState() => _PostLoginFlowState();
}

class _PostLoginFlowState extends State<PostLoginFlow> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWhenNewUser());
  }

  Future<void> _showWhenNewUser() async {
    if (_handled || !mounted) return;
    final state = context.read<AuthBloc>().state;
    if (state.status != AuthStatus.authenticated) return;
    final auth = state.authenticate;
    if (auth == null) return;
    // the welcome belongs to a new tenant: the GrowERP tenant itself and a user
    // who only registered into an existing company never start a trial
    if (auth.company?.name?.toLowerCase() == 'growerp') return;
    if (auth.user?.appsUsed.isNotEmpty ?? true) return;
    _handled = true;

    // Apple/Mac App Store reject trial messaging outside IAP;
    // suppress the trial welcome on those platforms in test.
    final skipTrialWelcome =
        (Platform.isIOS || Platform.isMacOS) &&
        GlobalConfiguration().get("test") == true;
    // A user who registered into an existing company does not own the trial,
    // only an admin starts one.
    if (!skipTrialWelcome && auth.user?.userGroup == UserGroup.admin) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => TrialWelcomeDialog(authenticate: auth),
      );
    }
    // Replace the old onboarding assistant with the
    // "Do you need an ERP system?" assessment.
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ErpAssessmentDialog(authenticate: auth),
    );
    // Mark this app as used so the welcome + assessment only appear on the
    // first login. Registering the app makes user.appsUsed non-empty next time.
    if (!mounted) return;
    try {
      final authBloc = context.read<AuthBloc>();
      final applicationId = authBloc.applicationId;
      await context.read<RestClient>().registerAppUsed(
        applicationId: applicationId,
      );
      // and in this session too: a menu reload rebuilds the router, and with it
      // this widget, which would otherwise open the welcome a second time
      final user = auth.user;
      if (user != null) {
        authBloc.add(
          AuthUpdateLocal(
            auth.copyWith(
              user: user.copyWith(appsUsed: [...user.appsUsed, applicationId]),
            ),
          ),
        );
      }
    } catch (_) {
      // Non-fatal: if registration fails the dialogs may show again next login,
      // but the dashboard below must not break.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
