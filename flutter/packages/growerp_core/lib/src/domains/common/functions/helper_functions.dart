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
import 'package:universal_io/io.dart';
import 'package:http/http.dart' show get;
import '../../domains.dart';

class HelperFunctions {
  static showMessage(
    BuildContext context,
    String? message,
    dynamic colors, {
    int? seconds,
  }) {
    if (message != null && message != "null") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(snackBar(context, colors, message, seconds: seconds));
    }
  }

  static showTopMessage(context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        dismissDirection: DismissDirection.up,
        duration: duration ?? const Duration(milliseconds: 1000),
        backgroundColor: Colors.yellow,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 10,
          right: 10,
        ),
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontSize: 20)),
      ),
    );
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
