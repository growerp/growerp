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

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class OnboardingTaskTest {
  /// filter the list without opening a row; [CommonTest.doNewSearch] also taps
  /// the found row which would open its dialog
  static Future<void> search(WidgetTester tester, String searchString) async {
    await CommonTest.enterText(tester, 'searchField', searchString);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  static Future<void> selectOnboardingTasks(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/hr/onboarding',
      'OnboardingTaskList',
    );
  }

  static Future<void> addOnboardingTasks(
    WidgetTester tester,
    List<OnboardingTask> onboardingTasks,
  ) async {
    for (final task in onboardingTasks) {
      await CommonTest.tapByKey(tester, 'addNew');
      await CommonTest.enterText(tester, 'description', task.description);
      await CommonTest.enterText(
        tester,
        'sequenceNum',
        task.sequenceNum.toString(),
      );
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForKey(tester, 'item0');
    }
    await checkOnboardingTasks(tester, onboardingTasks);
  }

  static Future<void> checkOnboardingTasks(
    WidgetTester tester,
    List<OnboardingTask> onboardingTasks,
  ) async {
    for (final task in onboardingTasks) {
      await search(tester, task.description);
      expect(
        CommonTest.getTextField('name0'),
        contains(task.description),
        reason: 'onboarding task ${task.description} should be in the list',
      );
    }
  }

  static Future<void> deleteOnboardingTask(
    WidgetTester tester,
    String description,
  ) async {
    await search(tester, description);
    await CommonTest.tapByKey(tester, 'delete0');
    await CommonTest.tapByKey(tester, 'continue');
    await CommonTest.waitForSnackbarToGo(tester);
  }
}
