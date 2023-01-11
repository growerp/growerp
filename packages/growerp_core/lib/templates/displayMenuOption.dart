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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../domains/domains.dart';
import '../../../templates/@templates.dart';

class DisplayMenuOption extends StatefulWidget {
  final MenuOption? menuOption; // display not an item from the list like chat
  final List<MenuOption> menuList; // menu list to be used
  final int menuIndex; // navigator rail menu selected
  final int? tabIndex; // tab selected, if none create new
  final TabItem? tabItem; // create new tab if tabIndex null
  final List<Widget>? actions; // actions at the appBar
  DisplayMenuOption({
    Key? key,
    this.menuOption,
    required this.menuList,
    required this.menuIndex,
    this.tabIndex,
    this.tabItem,
    this.actions,
  }) : super(key: key);

  @override
  _MenuOptionState createState() => _MenuOptionState();
}

class _MenuOptionState extends State<DisplayMenuOption>
    with SingleTickerProviderStateMixin {
  late int tabIndex;
  List<TabItem> tabItems = [];
  late String title;
  late String route;
  List<Widget> actions = [];
  Widget? leadAction;
  Widget? child;
  List<Widget> tabList = [];
  List<Widget> tabText = [];
  Map<int, FloatingActionButton> floatingActionButtonList = {};
  FloatingActionButton? floatingActionButton;
  List<BottomNavigationBarItem> bottomItems = [];
  TabController? _controller;
  late String displayMOFormKey;

  @override
  void initState() {
    super.initState();
    MenuOption menuOption =
        widget.menuOption ?? widget.menuList[widget.menuIndex];
    tabItems = menuOption.tabItems ?? [];
    title = menuOption.title;
    route = menuOption.route; // used also for key
    child = menuOption.child;
    leadAction = menuOption.leadAction;
    tabIndex = widget.tabIndex ?? 0;
    if (menuOption.floatButtonForm != null) {
      floatingActionButton = FloatingActionButton(
          key: Key("addNew"),
          onPressed: () async {
            await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return menuOption.floatButtonForm!;
                });
          },
          tooltip: 'Add New',
          child: Icon(Icons.add));
    }
    if (tabItems.isEmpty)
      displayMOFormKey =
          child.toString().replaceAll(new RegExp(r'[^(a-z,A-Z)]'), '');
    for (var i = 0; i < tabItems.length; i++) {
      // form key for testing
      displayMOFormKey = tabItems[i]
          .form
          .toString()
          .replaceAll(new RegExp(r'[^(a-z,A-Z)]'), '');
      print("=== current form key: $displayMOFormKey");
      // form to display
      tabList.add(tabItems[i].form);
      // text of tabs at top of screen (tablet, web)
      tabText.add(Align(
          alignment: Alignment.center,
          child: Text(tabItems[i].label, key: Key('tap$displayMOFormKey'))));
      // tabs at bottom of screen : phone
      bottomItems.add(BottomNavigationBarItem(
          icon: tabItems[i].icon,
          label: tabItems[i].label,
          tooltip: (i + 1).toString()));
      // floating actionbutton at each tab; not work with domain org
      if (tabItems[i].floatButtonRoute != null)
        floatingActionButtonList[i] = FloatingActionButton(
            key: Key("addNew"),
            onPressed: () async {
              await Navigator.pushNamed(
                  context, tabItems[tabIndex].floatButtonRoute!,
                  arguments: tabItems[tabIndex].floatButtonArgs);
            },
            tooltip: 'Add New',
            child: Icon(Icons.add));
      if (tabItems[i].floatButtonForm != null) {
        floatingActionButtonList[i] = FloatingActionButton(
            key: Key("addNew"),
            onPressed: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return tabItems[i].floatButtonForm!;
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
    actions = widget.actions ?? [];
    if (isPhone && route != '/')
      actions.add(IconButton(
          key: Key('homeButton'),
          icon: Icon(Icons.home),
          tooltip: 'Go Home',
          onPressed: () {
            if (route.startsWith('/acct'))
              Navigator.pushNamed(context, '/accounting',
                  arguments: FormArguments());
            else
              Navigator.pushNamed(context, '/', arguments: FormArguments());
          }));

    actions.add(IconButton(
        //  key: Key('topChatButton'), // causes a duplicate key?
        icon: Icon(Icons.chat),
        tooltip: 'Chat',
        onPressed: () async => {
              await showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) {
                  return ChatRoomListDialog();
                },
              )
            }));

    Authenticate authenticate = Authenticate();
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      switch (state.status) {
        case AuthStatus.authenticated:
        case AuthStatus.unAuthenticated:
          authenticate = state.authenticate!;
          break;
        default:
          authenticate = Authenticate();
      }
      if (tabItems.isEmpty) {
        // show simple page
        if (isPhone) // no navigation bar
          return simplePage(authenticate, isPhone);
        else // tablet or web show navigation
          return myNavigationRail(
            context,
            authenticate,
            simplePage(authenticate, isPhone),
            widget.menuIndex,
            widget.menuList,
          );
      } else {
        // show tabbar page
        if (isPhone)
          return tabPage(authenticate, isPhone);
        else
          return myNavigationRail(
            context,
            authenticate,
            tabPage(authenticate, isPhone),
            widget.menuIndex,
            widget.menuList,
          );
      }
    });
  }

  Widget simplePage(Authenticate authenticate, bool isPhone) {
    displayMOFormKey =
        child.toString().replaceAll(new RegExp(r'[^(a-z,A-Z)]'), '');
    print("=== current form key: $displayMOFormKey");
    return Scaffold(
        key: Key(route),
        appBar: AppBar(
            key: Key(displayMOFormKey),
            automaticallyImplyLeading: isPhone,
            leading: leadAction,
            title: appBarTitle(context, authenticate, title),
            actions: actions),
        drawer: myDrawer(context, authenticate, isPhone, widget.menuList),
        floatingActionButton: floatingActionButton,
        body: child);
  }

  Widget tabPage(Authenticate authenticate, bool isPhone) {
    displayMOFormKey = tabList[tabIndex]
        .toString()
        .replaceAll(new RegExp(r'[^(a-z,A-Z)]'), '');
    print("=== current form key: $displayMOFormKey");
    return Scaffold(
        key: Key(route),
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
            title: appBarTitle(
                context, authenticate, '$title ${bottomItems[tabIndex].label}'),
            actions: actions),
        drawer: myDrawer(context, authenticate, isPhone, widget.menuList),
        floatingActionButton: floatingActionButtonList[tabIndex],
        bottomNavigationBar: isPhone
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
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
            ? Center(child: tabList[tabIndex], key: Key(displayMOFormKey))
            : TabBarView(
                key: Key(displayMOFormKey),
                controller: _controller,
                children: tabList,
              ));
  }
}
