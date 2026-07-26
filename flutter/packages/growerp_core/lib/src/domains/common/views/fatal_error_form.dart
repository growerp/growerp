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
import 'package:go_router/go_router.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';

class FatalErrorForm extends StatelessWidget {
  final String message;
  final String? route;
  final String buttonText;

  const FatalErrorForm({
    super.key,
    required this.message,
    this.route,
    this.buttonText = 'Restart',
  });
  @override
  Widget build(BuildContext context) {
    final localizations = CoreLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            height: 200,
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 15),
            ),
          ),
          OutlinedButton(
            child: Text(localizations.restart),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}
