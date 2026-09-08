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

/// Shown while the app is waiting on the backend.
///
/// Every waiting state needs visible content: an empty widget while a rest call
/// runs is indistinguishable from a crashed app, which is what the app store
/// review reported as a black screen on launch.
/// When [onRetry] is given and the wait takes longer than [retryDelay], the
/// spinner is joined by an explanation and a retry button: a backend that never
/// answers otherwise leaves the user with a spinner and no way out.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({
    super.key,
    this.message = 'Loading...',
    this.onRetry,
    this.retryDelay = const Duration(seconds: 10),
  });

  final String message;
  final VoidCallback? onRetry;
  final Duration retryDelay;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  Timer? _timer;
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    if (widget.onRetry != null) {
      _timer = Timer(widget.retryDelay, () {
        if (mounted) setState(() => _showRetry = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('appLoadingScreen'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(widget.message, style: Theme.of(context).textTheme.titleLarge),
          if (_showRetry) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This is taking longer than expected.\n'
                'The server cannot be reached at the moment.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('retryStartup'),
              onPressed: () {
                setState(() => _showRetry = false);
                _timer?.cancel();
                _timer = Timer(widget.retryDelay, () {
                  if (mounted) setState(() => _showRetry = true);
                });
                widget.onRetry!();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
