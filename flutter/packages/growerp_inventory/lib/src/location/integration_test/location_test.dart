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

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class LocationTest {
  static Future<void> addLocations(
    WidgetTester tester,
    List<Location> locations, {
    bool check = true,
  }) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence;
    if (test.locations.isEmpty) {
      // not yet created
      test = test.copyWith(locations: locations);
      await enterLocationData(tester, locations);
      await PersistFunctions.persistTest(test);
    }
    if (check && test.locations[0].locationId == null) {
      await PersistFunctions.persistTest(
        test.copyWith(
          locations: await checkLocationDetail(tester, test.locations),
          sequence: seq,
        ),
      );
    }
  }

  static Future<void> enterLocationData(
    WidgetTester tester,
    List<Location> locations,
  ) async {
    for (Location location in locations) {
      if (location.locationId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(
          tester,
          searchString: location.locationId!,
        );
        expect(
          CommonTest.getTextField('topHeader').split('#')[1],
          location.locationId,
        );
      }
      await CommonTest.checkWidgetKey(tester, 'LocationDialog');
      await CommonTest.tapByKey(
        tester,
        'name',
      ); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', location.locationName!);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Location>> checkLocationDetail(
    WidgetTester tester,
    List<Location> locations,
  ) async {
    List<Location> newLocations = [];
    for (Location location in locations) {
      await CommonTest.doNewSearch(
        tester,
        searchString: location.locationName!,
      );
      // list
      expect(find.byKey(const Key('LocationDialog')), findsOneWidget);
      expect(
        CommonTest.getTextFormField('name'),
        equals(location.locationName!),
      );
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newLocations.add(location.copyWith(locationId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    return newLocations;
  }

  static Future<void> deleteLocations(
    WidgetTester tester,
    int numberOfDeletes,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    // clear any active search filter so all locations are visible
    await CommonTest.enterText(tester, 'searchField', '');
    await tester.pump(Duration(seconds: CommonTest.waitTime));
    await tester.pumpAndSettle(Duration(seconds: CommonTest.waitTime));
    // delete locations
    for (int x = 0; x < test.locations.length; x++) {
      await CommonTest.tapByKey(tester, "delete0");
      await CommonTest.tapByKey(
        tester,
        "continue",
        seconds: CommonTest.waitTime,
      );
    }

    // check locations deleted
    expect(find.text('No data found'), findsOneWidget);
  }

  static Future<void> updateLocations(
    WidgetTester tester,
    List<Location> newLocations,
  ) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.locations[0].locationName == newLocations[0].locationName) {
      return;
    }
    List<Location> updLocations = [];
    int index = 0;
    for (Location location in test.locations) {
      updLocations.add(
        location.copyWith(locationName: newLocations[index++].locationName!),
      );
    }
    test = test.copyWith(locations: updLocations);
    await enterLocationData(tester, test.locations);
    await checkLocationDetail(tester, test.locations);
    await PersistFunctions.persistTest(test);
  }
}
