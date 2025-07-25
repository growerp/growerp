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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_chat/growerp_chat.dart';
import 'package:growerp_models/growerp_models.dart';
import '../../growerp_core.dart';

class DisplayMenuOption extends StatefulWidget {
  final List<MenuOption> menuList; // menu list to be used
  final int menuIndex; // navigator rail menu selected
  final int? tabIndex; // tab selected, if none create new
  final TabItem? tabItem; // create new tab if tabIndex null
  final List<Widget> actions; // actions at the appBar
  const DisplayMenuOption({
    super.key,
    required this.menuList,
    required this.menuIndex,
    this.tabIndex,
    this.tabItem,
    this.actions = const [],
  });

  @override
  MenuOptionState createState() => MenuOptionState();
}

class MenuOptionState extends State<DisplayMenuOption>
    with SingleTickerProviderStateMixin {
  late int tabIndex;
  List<TabItem> tabItems = [];
  late String title;
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
  late String currentRoute = '';
  late bool isPhone;
  late AuthBloc authBloc;
  List<MenuOption> menuList = [];
  int menuIndex = 0;

  @override
  void initState() {
    super.initState();
    authBloc = context.read<AuthBloc>();
    // apply security
    int newIndex = 0;
    for (final option in widget.menuList) {
      if (option.userGroups != null &&
          option.userGroups!
              .contains(authBloc.state.authenticate?.user?.userGroup)) {
        menuList.add(option);
        if (option.route == widget.menuList[widget.menuIndex].route) {
          menuIndex = newIndex;
        }
        newIndex++;
      }
    }

    if (menuList.isEmpty) {
      menuList = [
        MenuOption(
            image: 'packages/growerp_core/images/dashBoardGrey.png',
            selectedImage: 'packages/growerp_core/images/dashBoard.png',
            title: 'Main',
            route: '/',
            child: Container(
              height: 45,
              color: Colors.black,
              child: const Center(
                child: Text('No Access to any option',
                    style: TextStyle(color: Colors.red, fontSize: 25)),
              ),
            )),
        //navigation rail needs at least 2
        MenuOption(
            image: 'packages/growerp_core/images/dashBoardGrey.png',
            selectedImage: 'packages/growerp_core/images/dashBoard.png',
            title: '',
            route: '/',
            child: Container())
      ];
      menuIndex = 0;
    }

    MenuOption menuOption = menuList[menuIndex];
    tabItems = menuOption.tabItems ?? [];
    title = menuOption.title;
    child = menuOption.child;
    tabIndex = widget.tabIndex ?? 0;
    if (tabItems.isEmpty) {
      displayMOFormKey =
          child.toString().replaceAll(RegExp(r'[^(a-z,A-Z)]'), '');
      // debugPrint("==1== current form key: $displayMOFormKey");
    }
    for (var i = 0; i < tabItems.length; i++) {
      // form key for testing
      displayMOFormKey =
          tabItems[i].form.toString().replaceAll(RegExp(r'[^(a-z,A-Z)]'), '');
      //debugPrint("==1== current form key: $displayMOFormKey");
      // form to display
      tabList.add(tabItems[i].form);
      // text of tabs at top of screen (tablet, web)
      tabText.add(Align(
          alignment: Alignment.center,
          child: Text(tabItems[i].label, key: Key('tap$displayMOFormKey'))));
      // tabs at bottom of screen : phone
      bottomItems.add(BottomNavigationBarItem(
          icon: tabItems[i].icon,
          label: tabItems[i].label.replaceAll('\n', ' '),
          tooltip: (i + 1).toString()));
      // floating actionbutton at each tab; not work with domain org
      if (tabItems[i].floatButtonRoute != null) {
        floatingActionButtonList[i] = FloatingActionButton(
            key: const Key("addNew"),
            heroTag: "floatBtn_route_$i",
            onPressed: () async {
              await Navigator.pushReplacementNamed(
                  context, tabItems[tabIndex].floatButtonRoute!,
                  arguments: tabItems[tabIndex].floatButtonArgs);
            },
            tooltip: 'Add New',
            child: const Icon(Icons.add));
      }
      if (tabItems[i].floatButtonForm != null) {
        floatingActionButtonList[i] = FloatingActionButton(
            key: const Key("addNew"),
            heroTag: "floatBtn_form_$i",
            onPressed: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return tabItems[i].floatButtonForm!;
                  });
            },
            tooltip: 'Add New',
            child: const Icon(Icons.add));
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
    currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    isPhone = isAPhone(context);
    return BlocBuilder<ChatRoomBloc, ChatRoomState>(builder: (context, state) {
      if (state.status == ChatRoomStatus.success) {
        actions = List.of(widget.actions);
        List<ChatRoom> unReadRooms = context
            .read<ChatRoomBloc>()
            .state
            .chatRooms
            .where((element) => element.hasRead == false)
            .toList();
        actions.insert(
            0,
            IconButton(
              key: const Key('chatButton'), // causes a duplicate key?
              icon: Badge(
                  label: unReadRooms.isNotEmpty
                      ? Text(unReadRooms.length.toString())
                      : null,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.chat)),
              padding: EdgeInsets.zero,
              tooltip: unReadRooms.isEmpty ? 'Chat' : unReadRooms.toString(),
              onPressed: () async => {
                await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return const ChatRoomListDialog();
                  },
                )
              },
            ));

        if (currentRoute != '/') {
          actions.add(IconButton(
              key: const Key('homeButton'),
              icon: const Icon(Icons.home),
              tooltip: 'Go Home',
              onPressed: () {
                if (currentRoute.startsWith('/acct')) {
                  Navigator.pushNamed(context, '/accounting');
                } else {
                  Navigator.pushNamed(context, '/');
                }
              }));
        }

        Widget simplePage(bool isPhone) {
          displayMOFormKey =
              child.toString().replaceAll(RegExp(r'[^(a-z,A-Z)]'), '');
          // debugPrint("==2-simple= current form key: $displayMOFormKey");

          return ScaffoldMessenger(
              child: Scaffold(
            key: Key(currentRoute),
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                key: Key(displayMOFormKey),
                automaticallyImplyLeading: isPhone,
                leading: leadAction,
                title: appBarTitle(context, title, isPhone),
                actions: actions),
            drawer: myDrawer(context, isPhone, menuList),
            floatingActionButton: floatingActionButton,
            body: BlocListener<NotificationBloc, NotificationState>(
                listener: (context, notiFicationState) {
                  if (notiFicationState.status == NotificationStatus.success &&
                      notiFicationState.notifications.isNotEmpty) {
                    String messages = '';
                    for (final (index, note)
                        in notiFicationState.notifications.indexed) {
                      messages +=
                          "${note.message!["message"]}${index < notiFicationState.notifications.length - 1 ? '\n' : ''}";
                    }
                    HelperFunctions.showTopMessage(context, messages);
                  }
                },
                child: child!),
          ));
        }

        Widget tabPage(bool isPhone) {
          displayMOFormKey = tabList[tabIndex]
              .toString()
              .replaceAll(RegExp(r'[^(a-z,A-Z)]'), '');
          Color tabSelectedBackground =
              Theme.of(context).colorScheme.onSecondary;
          //debugPrint("==3-tab= current form key: $displayMOFormKey");
          List<Widget> tabChildren = [
            Expanded(
                child: isPhone
                    ? Center(
                        key: Key(displayMOFormKey), child: tabList[tabIndex])
                    : TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        key: Key(displayMOFormKey),
                        controller: _controller,
                        children: tabList,
                      ))
          ];

          return Scaffold(
              key: Key(currentRoute),
              appBar: AppBar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  automaticallyImplyLeading: isPhone,
                  bottom: isPhone
                      ? null
                      : TabBar(
                          controller: _controller,
                          labelPadding: const EdgeInsets.all(5.0),
                          indicatorSize: TabBarIndicatorSize.label,
                          indicator: BoxDecoration(
                            color: tabSelectedBackground,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10)),
                          ),
                          tabs: tabText,
                        ),
                  title: appBarTitle(
                      context,
                      '$title ${isPhone ? '\n' : ', '}${tabItems[tabIndex].label}',
                      isPhone),
                  actions: actions),
              drawer: myDrawer(context, isPhone, menuList),
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
              body: Column(children: tabChildren));
        }

        if (!kReleaseMode || GlobalConfiguration().get("test") == true) {
          return Banner(
              message: "test",
              color: Colors.red,
              location: BannerLocation.topStart,
              child: showPage(simplePage, context, tabPage));
        } else {
          return showPage(simplePage, context, tabPage);
        }
      } else {
        return const Center(child: LoadingIndicator());
      }
    });
  }

  Widget showPage(Widget Function(bool isPhone) simplePage,
      BuildContext context, Widget Function(bool isPhone) tabPage) {
    if (tabItems.isEmpty) {
      // show simple page
      if (isPhone) {
        return simplePage(isPhone);
      } else {
        return myNavigationRail(
          context,
          simplePage(isPhone),
          menuIndex,
          menuList,
        );
      }
    } else {
      // show tabbar page
      if (isPhone) {
        return tabPage(isPhone);
      } else {
        return myNavigationRail(
          context,
          tabPage(isPhone),
          menuIndex,
          menuList,
        );
      }
    }
  }
}
