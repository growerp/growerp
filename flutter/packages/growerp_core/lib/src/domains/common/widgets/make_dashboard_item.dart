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
import 'package:responsive_framework/responsive_framework.dart';

import '../common.dart';

Card makeDashboardItem(String key, BuildContext context, MenuOption menuOption,
    List<String> subTitles) {
  bool phone = ResponsiveBreakpoints.of(context).isMobile;

  List<Widget> textList = [
    Center(child: Image.asset(menuOption.selectedImage, height: 80.0)),
    Center(
        child: Text(menuOption.title.replaceAll('\n', ''),
            style: TextStyle(
                fontSize: phone ? 15 : 25, fontWeight: FontWeight.bold),
            key: Key("${key}Title")))
  ];
  int index = 0;
  for (final test in subTitles) {
    textList.add(Center(
      child: Text(test,
          style: TextStyle(fontSize: phone ? 12 : 20),
          key: Key("${key}SubTitle${index++}")),
    ));
  }
  return Card(
      elevation: 1.0,
      margin: const EdgeInsets.all(5.0),
      child: Container(
        decoration: const BoxDecoration(),
        child: InkWell(
          key: Key(key),
          onTap: () {
            Navigator.pushNamed(context, menuOption.route);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            verticalDirection: VerticalDirection.down,
            children: textList,
          ),
        ),
      ));
}
