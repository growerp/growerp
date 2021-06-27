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

import 'package:core/blocs/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:core/templates/@templates.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:responsive_framework/responsive_framework.dart';

class DisplayMenuList extends StatefulWidget {
  final scaffoldMessengerKey;
  final List<MenuItem> menuList; // menu list to be used
  final int menuIndex; // navigator rail menu selected
  final int? tabIndex; // tab selected, if none create new
  final TabItem? tabItem; // create new tab if tabIndex null
  final List<Widget>? actions;
  DisplayMenuList({
    this.scaffoldMessengerKey,
    Key? key,
    required this.menuList,
    required this.menuIndex,
    this.tabIndex,
    this.tabItem,
    this.actions,
  }) : super(key: key);

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<DisplayMenuList>
    with SingleTickerProviderStateMixin {
  late int tabIndex;
  List<TabItem>? tabItems = [];
  late String title;
  Widget? leadAction;
  Widget? child;
  List<Widget> tabList = [];
  List<Widget> tabText = [];
  Map<int, FloatingActionButton> floatingActionButtonList = {};
  FloatingActionButton? floatingActionButton;
  List<BottomNavigationBarItem>? bottomItems = [];
  TabController? _controller;

  @override
  void initState() {
    super.initState();
    MenuItem menuItem = widget.menuList[widget.menuIndex];
    tabItems = menuItem.tabItems;
    title = menuItem.title;
    child = menuItem.child;
    leadAction = menuItem.leadAction;
    tabIndex = widget.tabIndex ?? 0;
    if (menuItem.floatButtonForm != null) {
      floatingActionButton = FloatingActionButton(
          key: Key("addNew"),
          onPressed: () async {
            await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return menuItem.floatButtonForm!;
                });
          },
          tooltip: 'Add New',
          child: Icon(Icons.add));
    }
    if (tabItems != null)
      for (var i = 0; i < tabItems!.length; i++) {
        // form to display
        tabList.add(tabItems![i].form);
        // text of tabs at top of screen (tablet, web)
        tabText.add(Align(
            alignment: Alignment.center, child: Text(tabItems![i].label)));
        // tabs at bottom of screen : phone
        bottomItems!.add(BottomNavigationBarItem(
            icon: tabItems![i].icon, label: tabItems![i].label));
        // floating actionbutton at each tab
        if (tabItems![i].floatButtonRoute != null)
          floatingActionButtonList[i] = FloatingActionButton(
              key: Key("addNew"),
              onPressed: () async {
                await Navigator.pushNamed(
                    context, tabItems![tabIndex].floatButtonRoute!,
                    arguments: tabItems![tabIndex].floatButtonArgs);
              },
              tooltip: 'Add New',
              child: Icon(Icons.add));
        if (tabItems![i].floatButtonForm != null) {
          floatingActionButtonList[i] = FloatingActionButton(
              key: Key("addNew"),
              onPressed: () async {
                await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return tabItems![i].floatButtonForm!;
                    });
              },
              tooltip: 'Add New',
              child: Icon(Icons.add));
        }
      }

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
    late Authenticate authenticate;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      if (tabItems == null) {
        // show simple page
        if (isPhone) // no navigation bar
          return simplePage(authenticate, isPhone, widget.scaffoldMessengerKey);
        else // tablet or web show navigation
          return myNavigationRail(
            context,
            authenticate,
            simplePage(authenticate, isPhone, widget.scaffoldMessengerKey),
            widget.menuIndex,
            widget.menuList,
          );
      } else {
        // show tabbar page
        if (isPhone)
          return tabPage(authenticate, isPhone, widget.scaffoldMessengerKey);
        else
          return myNavigationRail(
            context,
            authenticate,
            tabPage(authenticate, isPhone, widget.scaffoldMessengerKey),
            widget.menuIndex,
            widget.menuList,
          );
      }
    });
  }

  Widget simplePage(
      Authenticate authenticate, bool isPhone, scaffoldMessengerKey) {
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
            appBar: AppBar(
                key: Key(child.toString()),
                automaticallyImplyLeading: isPhone,
                leading: leadAction,
                title: AppBarTitle(context, authenticate, title),
                actions: widget.actions),
            drawer: myDrawer(context, authenticate, isPhone, widget.menuList),
            floatingActionButton: floatingActionButton,
            body: child));
  }

  Widget tabPage(
      Authenticate authenticate, bool isPhone, scaffoldMessengerKey) {
    return ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
            appBar: AppBar(
                key: Key(tabList[tabIndex].toString()),
                automaticallyImplyLeading: isPhone,
                bottom: isPhone
                    ? null
                    : TabBar(
                        key: Key(tabText[tabIndex].toString()),
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
                title: AppBarTitle(context, authenticate, title),
                actions: widget.actions),
            drawer: myDrawer(context, authenticate, isPhone, widget.menuList),
            floatingActionButton: floatingActionButtonList[tabIndex],
            bottomNavigationBar: isPhone
                ? BottomNavigationBar(
                    items: bottomItems!,
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
                    children: tabList,
                  )));
  }
}
