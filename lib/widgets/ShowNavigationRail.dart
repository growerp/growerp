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
import '../blocs/@blocs.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../models/@models.dart';
import '@widgets.dart';

/// Checks connection and add navigation rail
///
/// Shows the navigation rail when loggedin and having tablet or web
class ShowNavigationRail extends StatelessWidget {
  /// widget to continue
  final Widget widget;

  /// item on the rail which is selected
  final int selectedIndex;
  final Authenticate authenticate;
  const ShowNavigationRail(this.widget,
      [this.selectedIndex, this.authenticate]);
  @override
  Widget build(BuildContext context) {
    Authenticate authenticate = this.authenticate;
    bool loggedIn = false;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) {
        authenticate = state.authenticate;
        loggedIn = true;
      }
      return this.authenticate != null ||
              (loggedIn && !ResponsiveWrapper.of(context).isSmallerThan(TABLET))
          ? myNavigationRail(context, authenticate, widget, selectedIndex)
          : widget;
    });
  }
}
