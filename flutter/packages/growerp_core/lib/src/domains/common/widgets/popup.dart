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
import '../../../../growerp_core.dart';

Widget popUp({
  Widget? child,
  String title = '',
  double height = 400,
  double? width,
  double padding = 10,
  bool? closeButton = true,
  required BuildContext context,
}) {
  if (width == null) {
    isPhone(context) ? width = 450 : width = 700;
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Text(
                  title,
                  key: const Key('topHeader'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Padding(padding: EdgeInsets.all(padding), child: child),
              ),
            ),
          ],
        ),
      ),
      if (closeButton == true)
        const Positioned(top: 15, right: 15, child: DialogCloseButton()),
    ],
  );
}
