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
    String subTitle, String subTitle1, String subTitle2, String subTitle3) {
  bool phone = ResponsiveWrapper.of(context).isSmallerThan(DESKTOP);
  return Card(
      elevation: 1.0,
      margin: new EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(220, 220, 220, 1.0)),
        child: new InkWell(
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
              SizedBox(height: 2.0),
              Center(
                  child: Image.asset(menuOption.selectedImage, height: 80.0)),
              Center(
                child: Text("${menuOption.title}",
                    style: TextStyle(
                        fontSize: phone ? 15 : 25,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 2.0),
              Center(
                child: Text(subTitle,
                    style: TextStyle(
                        fontSize: phone ? 12 : 20, color: Colors.black)),
              ),
              SizedBox(height: 2.0),
              Center(
                child: Text(subTitle1,
                    style: TextStyle(
                        fontSize: phone ? 12 : 20, color: Colors.black)),
              ),
              Visibility(
                  visible: subTitle2.isNotEmpty,
                  child: Column(children: [
                    SizedBox(height: 2.0),
                    Center(
                      child: Text(subTitle2,
                          style: TextStyle(
                              fontSize: phone ? 12 : 20, color: Colors.black)),
                    )
                  ])),
              Visibility(
                  visible: subTitle3.isNotEmpty,
                  child: Column(children: [
                    SizedBox(height: 2.0),
                    Center(
                      child: Text(subTitle3,
                          style: TextStyle(
                              fontSize: phone ? 12 : 20, color: Colors.black)),
                    )
                  ]))
            ],
          ),
        ),
      ));
}
