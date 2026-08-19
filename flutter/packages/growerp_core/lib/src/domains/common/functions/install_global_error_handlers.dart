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

/// Installs app wide error handlers.
///
/// Without these an error during startup or in a build method leaves the app on
/// an empty window with no message and no way back: exactly the "stuck on a
/// black screen upon launch" the app store review reported. Call directly after
/// WidgetsFlutterBinding.ensureInitialized().
void installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('===growerp framework error: ${details.exceptionAsString()}');
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('===growerp uncaught error: $error');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) =>
      StartupErrorScreen(message: details.exceptionAsString());
}

/// Replaces the default grey/red error box with a readable message, so a build
/// failure shows what went wrong instead of a blank rectangle. Also usable as
/// the root widget when startup itself fails, so runApp() always gets called.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
