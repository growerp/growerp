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

Card makeDashboardItem(
    String key, BuildContext context, MenuOption menuOption, String subTitle,
    [String? subTitle1,
    String? subTitle2,
    String? subTitle3,
    String? subTitle4]) {
  bool phone = ResponsiveWrapper.of(context).isSmallerThan(DESKTOP);
  return Card(
      elevation: 1.0,
      margin: const EdgeInsets.all(8.0),
      child: Container(
        decoration:
            const BoxDecoration(color: Color.fromRGBO(220, 220, 220, 1.0)),
        child: InkWell(
          key: Key(key),
          onTap: () {
            Navigator.pushNamed(context, menuOption.route,
                arguments: FormArguments());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            verticalDirection: VerticalDirection.down,
            children: <Widget>[
              const SizedBox(height: 2.0),
              Center(
                  child: Image.asset(menuOption.selectedImage, height: 80.0)),
              Center(
                child: Text(menuOption.title,
                    style: TextStyle(
                        fontSize: phone ? 15 : 25,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                    key: Key("${key}Title")),
              ),
              const SizedBox(height: 2.0),
              Center(
                child: Text(subTitle,
                    style: TextStyle(
                        fontSize: phone ? 12 : 20, color: Colors.black),
                    key: Key("${key}SubTitle")),
              ),
              const SizedBox(height: 2.0),
              if (subTitle1 != null)
                Center(
                  child: Text(subTitle1,
                      style: TextStyle(
                          fontSize: phone ? 12 : 20, color: Colors.black),
                      key: Key("${key}SubTitle1")),
                ),
              const SizedBox(height: 2.0),
              if (subTitle2 != null)
                Column(children: [
                  const SizedBox(height: 2.0),
                  Center(
                    child: Text(subTitle2,
                        style: TextStyle(
                            fontSize: phone ? 12 : 20, color: Colors.black),
                        key: Key("${key}SubTitle2")),
                  )
                ]),
              const SizedBox(height: 2.0),
              if (subTitle3 != null)
                Center(
                  child: Text(subTitle3,
                      style: TextStyle(
                          fontSize: phone ? 12 : 20, color: Colors.black),
                      key: Key("${key}SubTitle3")),
                ),
              const SizedBox(height: 2.0),
              if (subTitle4 != null)
                Center(
                  child: Text(subTitle4,
                      style: TextStyle(
                          fontSize: phone ? 12 : 20, color: Colors.black),
                      key: Key("${key}SubTitle4")),
                )
            ],
          ),
        ),
      ));
}
