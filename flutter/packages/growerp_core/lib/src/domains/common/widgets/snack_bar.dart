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

import 'package:flutter/material.dart';

SnackBar snackBar(BuildContext context, Color colors, String message) {
  var screenWidth = MediaQuery.of(context).size.width;
  return SnackBar(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    duration: Duration(milliseconds: colors == Colors.red ? 5000 : 2000),
    content: Container(
        padding: const EdgeInsets.all(16.0),
        width: screenWidth < 800 ? screenWidth * 0.8 : 500,
        child: Text(message)),
    backgroundColor: colors,
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(
      key: const Key('dismiss'),
      label: 'Dismiss',
      textColor: Colors.yellow,
      onPressed: () {
        // Hide the snackbar before its duration ends
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      },
    ),
  );
}
