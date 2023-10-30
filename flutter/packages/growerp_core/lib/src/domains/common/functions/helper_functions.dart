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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'dart:io';
import 'package:http/http.dart' show get;
import '../../domains.dart';

class HelperFunctions {
  static showMessage(BuildContext context, String? message, dynamic colors,
      {int? seconds}) {
    if (message != null && message != "null") {
      ScaffoldMessenger.of(context)
          .showSnackBar(snackBar(context, colors, message, seconds: seconds));
    }
  }

  static showTopMessage(dynamic scaffoldKey, String? message, [int? duration]) {
    if (message != null) {
      scheduleMicrotask(() => scaffoldKey.currentState.showSnackBar(SnackBar(
            duration: Duration(seconds: duration ?? 2),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message),
              ],
            ),
            backgroundColor: Colors.green,
          )));
    }
  }

  static Future<Uint8List?> getResizedImage(imagePath) async {
    if (imagePath != null) {
      const LoadingIndicator();
      Uint8List imageData;
      if (kIsWeb) {
        var response = await get(Uri.parse(imagePath));
        imageData = response.bodyBytes;
      } else {
        imageData = File(imagePath).readAsBytesSync();
      }
      if (imageData.length > 200000) {
        image.Image img = image.decodeImage(imageData)!;
        image.Image resized = image.copyResize(img, width: -1, height: 200);
        imageData = image.encodeJpg(resized);
      }
      return imageData;
    } else {
      return null;
    }
  }
}
