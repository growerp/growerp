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

import 'package:growerp_core/src/extensions.dart';
import 'package:logger/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(
        lineLength: 133,
        methodCount: 0), // Use the PrettyPrinter to format and print log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    logger.i("Event: ${transition.event.toString().truncate(110)}\n"
        "Curr.State: ${transition.currentState.toString().truncate(110)}\n"
        "Next State: ${transition.nextState.toString().truncate(110)}");
  }
}
