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
import 'package:flutter/material.dart' hide Image;
import 'package:image/image.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' show get;

class HelperFunctions {
  static showMessage(context, message, colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$message'),
          ],
        ),
        backgroundColor: colors,
      ),
    );
  }

  static showTopMessage(_scaffoldKey, message) {
    if (message != null)
      scheduleMicrotask(() => _scaffoldKey.currentState.showSnackBar(SnackBar(
            duration: const Duration(seconds: 1),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$message'),
              ],
            ),
            backgroundColor: Colors.green,
          )));
  }

  static Future toBase64(imagePath) async {
    if (imagePath != null) {
      Image image;
      if (kIsWeb) {
        var response = await get(imagePath);
        image = decodeImage(response.bodyBytes);
      } else {
        image = decodeImage(File(imagePath).readAsBytesSync());
      }
      image = gaussianBlur(copyResize(image, width: 300), 3);
      return base64Encode(encodePng(image));
    }
    return null;
  }
}
