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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/forms/@forms.dart';
import 'package:models/@models.dart';
import '@templates.dart';

class MainTemplate extends StatefulWidget {
  @required
  final List<Widget>? actions; // actions at the appbar
  @required
  final int? tabIndex; // tab selected
  @required
  final int? menuIndex; // navigator rail menu selected
  @required
  final Widget? child; // child page when no tabs required
  @required
  final List<MapItem>? mapItems; // for tabs, null if no tabs
  @required
  final List<MenuItem>? menu;
  final leadAction; // single actionButton on the lef like back button
  MainTemplate({
    Key? key,
    this.actions,
    this.tabIndex,
    this.menuIndex,
    this.child,
    this.mapItems,
    this.menu,
    this.leadAction,
  }) : super(key: key);

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<MainTemplate>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late int tabIndex;
  List<Widget> tabList = [];
  List<Widget> tabText = [];
  List<FloatingActionButton?> floatingActionButtonList = [];
  List<BottomNavigationBarItem> bottomItems = [];
  TabController? _controller;

  @override
  void initState() {
    super.initState();
    tabIndex = widget.tabIndex ?? 0;
    widget.mapItems?.forEach((x) => {
          // form to display
          tabList.add(x.form!),
          // text of tabs at top of screen (tablet, web)
          tabText
              .add(Align(alignment: Alignment.center, child: Text(x.label!))),
          // tabs t bottom of screen : phone
          bottomItems
              .add(BottomNavigationBarItem(icon: x.icon!, label: x.label)),
          // floating actionbutton at each tab
          (x.floatButtonRoute == null)
              ? floatingActionButtonList.add(null)
              : floatingActionButtonList.add(FloatingActionButton(
                  onPressed: () async {
                    await Navigator.pushNamed(
                        context, widget.mapItems![tabIndex].floatButtonRoute!,
                        arguments: widget.mapItems![tabIndex].floatButtonArgs);
                  },
                  tooltip: 'Add New',
                  child: Icon(Icons.add)))
        });
    _controller = TabController(
      length: tabList.length,
      vsync: this,
      initialIndex: widget.tabIndex ?? 0,
    );
    _controller!.addListener(() {
      setState(() {
        tabIndex = _controller!.index;
      });
    });
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    Authenticate? authenticate;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthProblem)
        return FatalErrorForm("Internet or server problem?");
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      if (widget.mapItems == null) {
        // show simple page
        if (isPhone) // no navigation bar
          return simplePage(authenticate, isPhone);
        else // tablet or web show navigation
          return myNavigationRail(context, authenticate!,
              simplePage(authenticate, isPhone), widget.menuIndex, widget.menu);
      } else {
        // show tabbar page
        if (isPhone)
          return tabPage(authenticate, isPhone);
        else
          return myNavigationRail(context, authenticate!,
              tabPage(authenticate, isPhone), widget.menuIndex, widget.menu);
      }
    });
  }

  Widget simplePage(Authenticate? authenticate, bool isPhone) {
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
            appBar: AppBar(
                key: Key('DashBoardAuth'),
                automaticallyImplyLeading: isPhone,
                leading: widget.leadAction,
                title: companyLogo(context, authenticate,
                    authenticate?.company?.name ?? 'Company??'),
                actions: widget.actions),
            drawer: myDrawer(context, authenticate, isPhone, widget.menu),
            body: widget.child));
  }

  Widget tabPage(Authenticate? authenticate, bool isPhone) {
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: isPhone,
                bottom: isPhone
                    ? null
                    : TabBar(
                        controller: _controller,
                        labelPadding: EdgeInsets.all(10.0),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10)),
                            color: Colors.white),
                        tabs: tabText,
                      ),
                title: companyLogo(context, authenticate,
                    authenticate?.company?.name ?? 'Company??'),
                actions: widget.actions),
            drawer: myDrawer(context, authenticate, isPhone, widget.menu),
            floatingActionButton: floatingActionButtonList[tabIndex],
            bottomNavigationBar: isPhone
                ? BottomNavigationBar(
                    items: bottomItems,
                    currentIndex: tabIndex,
                    selectedItemColor: Colors.amber[800],
                    onTap: (index) {
                      setState(() {
                        tabIndex = index;
                      });
                    })
                : null,
            body: isPhone
                ? Center(child: tabList[tabIndex])
                : TabBarView(
                    controller: _controller,
                    children: tabList as List<Widget>,
                  )));
  }
}
