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
import '../../domains.dart';

Widget PopUpDialogNoScaffold({
  required BuildContext context,
  required List<Widget> children,
  String title = '',
  double height = 400,
  double width = 400,
  Key key = const Key('popUp'),
}) {
  return Dialog(
      insetPadding: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
            width: width,
            height: height,
            child: Column(children: [
              Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorDark,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      )),
                  child: Center(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(child: Column(children: children)),
              ))
            ])),
        Positioned(top: 10, right: 10, child: DialogCloseButton())
      ]));
}
