// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      // Return false if the screenshot is invalid.
      // TODO(yjbanov): implement, see https://github.com/flutter/flutter/issues/86120
      final File image =
          await File('screenshots/$screenshotName.png').create(recursive: true);
      image.writeAsBytesSync(screenshotBytes);
      print("======================screenshot==============");
      // Here is an example of using an argument that was passed in via the
      // optional 'args' Map.
      if (args != null) {
        final String? someArgumentValue = args['someArgumentKey'] as String?;
        return someArgumentValue != null;
      }
      return true;
    },
  );
}
