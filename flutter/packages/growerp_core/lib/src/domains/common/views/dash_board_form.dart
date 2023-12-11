/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

class DashBoardForm extends StatelessWidget {
  final List<Widget> dashboardItems;

  const DashBoardForm({super.key, this.dashboardItems = const []});

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    int widthAxisCount = isPhone ? 2 : 3;
    int heightAxisCount = isPhone ? 3 : 2;
    double width = MediaQuery.of(context).size.width - (isPhone ? 0 : 60);
    double height = MediaQuery.of(context).size.height - (isPhone ? 110 : 60);
    double ratioWidth = width / widthAxisCount;
    double ratioHeight = height / heightAxisCount;
    return Container(
      key: const Key('dashboard'),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: GridView.count(
        childAspectRatio: ratioWidth / ratioHeight,
        crossAxisCount: isPhone ? 2 : 3,
        padding: const EdgeInsets.all(3.0),
        children: dashboardItems,
      ),
    );
  }
}
