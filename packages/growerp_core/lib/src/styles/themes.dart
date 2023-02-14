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

class Themes {
  Themes._();

  static ThemeData formTheme = ThemeData.light().copyWith(
    brightness: Brightness.light,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFF4baa9b)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFFce5310)),
      ),
    ),
    primaryColorDark: const Color.fromARGB(255, 11, 70, 61),
    cardColor: Colors.white,
    canvasColor: Colors.white, // modal popup background
    scaffoldBackgroundColor: Colors.white,
//    iconTheme: IconThemeData(color: Colors.black),
    appBarTheme: const AppBarTheme(
      color: Color(0xFF4baa9b),
      elevation: 0,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: const Color(0xFF4baa9b),
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    hintColor: const Color(0xFF4baa9b),
    disabledColor: const Color(0x80FFFFFF),
    dividerColor: Colors.white30,
    unselectedWidgetColor: Colors.black,
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4baa9b),
    )),
  );
}
