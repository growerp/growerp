/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class LocationTest {
  static Future<void> addLocations(
      WidgetTester tester, List<Location> locations,
      {bool check = true}) async {
    SaveTest test = await PersistFunctions.getTest();
    int seq = test.sequence;
    if (test.locations.isEmpty) {
      // not yet created
      test = test.copyWith(locations: locations);
      await enterLocationData(tester, locations);
      await PersistFunctions.persistTest(test);
    }
    if (check && test.locations[0].locationId == null) {
      await PersistFunctions.persistTest(test.copyWith(
        locations: await checkLocationDetail(tester, test.locations),
        sequence: seq,
      ));
    }
  }

  static Future<void> enterLocationData(
      WidgetTester tester, List<Location> locations) async {
    for (Location location in locations) {
      if (location.locationId == null) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doSearch(tester, searchString: location.locationId!);
        await CommonTest.tapByKey(tester, 'edit0');
        expect(CommonTest.getTextField('topHeader').split('#')[1],
            location.locationId);
      }
      await CommonTest.checkWidgetKey(tester, 'LocationDialog');
      await CommonTest.tapByKey(
          tester, 'name'); // required because keyboard come up
      await CommonTest.enterText(tester, 'name', location.locationName!);
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<List<Location>> checkLocationDetail(
      WidgetTester tester, List<Location> locations) async {
    List<Location> newLocations = [];
    for (Location location in locations) {
      await CommonTest.doSearch(tester, searchString: location.locationName!);
      // list
      expect(CommonTest.getTextField('locName0'),
          startsWith(location.locationName!));
      await CommonTest.tapByKey(tester, 'edit0');
      expect(find.byKey(const Key('LocationDialog')), findsOneWidget);
      expect(
          CommonTest.getTextFormField('name'), equals(location.locationName!));
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      newLocations.add(location.copyWith(locationId: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return newLocations;
  }

  static Future<void> deleteLocations(
      WidgetTester tester, int numberOfDeletes) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.locations.length;
    await CommonTest.refresh(tester);
    expect(find.byKey(const Key('locationItem')), findsNWidgets(count));
    await CommonTest.tapByKey(tester, 'delete${count - 1}', seconds: 5);
    expect(find.byKey(const Key('locationItem')), findsNWidgets(count - 1));
    PersistFunctions.persistTest(test.copyWith(
        locations: test.locations.sublist(0, test.locations.length - 1)));
  }

  static Future<void> updateLocations(
      WidgetTester tester, List<Location> newLocations) async {
    SaveTest test = await PersistFunctions.getTest();
    // check if already modified then skip
    if (test.locations[0].locationName == newLocations[0].locationName) {
      return;
    }
    List<Location> updLocations = [];
    int index = 0;
    for (Location location in test.locations) {
      updLocations.add(location.copyWith(
        locationName: newLocations[index++].locationName!,
      ));
    }
    test = test.copyWith(locations: updLocations);
    await enterLocationData(tester, test.locations);
    await checkLocationDetail(tester, test.locations);
    await PersistFunctions.persistTest(test);
  }
}
