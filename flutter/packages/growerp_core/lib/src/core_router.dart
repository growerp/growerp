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
import 'domains/domains.dart';

// https://medium.com/flutter-community/flutter-navigation-cheatsheet-a-guide-to-named-routing-dc642702b98c
Route<dynamic> coreRoute(RouteSettings settings) {
  debugPrint(
    ">>>NavigateTo { ${settings.name} with: ${settings.arguments.toString()} }",
  );
  switch (settings.name) {
    case '/about':
      return MaterialPageRoute(builder: (context) => const AboutForm());
    default:
      return MaterialPageRoute(
        builder: (context) => FatalErrorForm(
          message: "Routing not found for request: ${settings.name}",
        ),
      );
  }
}
