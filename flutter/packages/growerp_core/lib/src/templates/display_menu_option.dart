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
import 'package:universal_io/io.dart';
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
  String displayMOFormKey = 'DefaultPage';
  String currentRoute = '';
  late bool isPhone;
  late AuthBloc authBloc;
  List<MenuOption> menuList = [];
  int menuIndex = 0;
  CoreLocalizations? _localizations;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _initialize(BuildContext context) {
    authBloc = context.read<AuthBloc>();
    // apply security
    int newIndex = 0;
    String? targetRoute;

    // Safely get the target route
    if (widget.menuIndex >= 0 && widget.menuIndex < widget.menuList.length) {
      targetRoute = widget.menuList[widget.menuIndex].route;
    }

    for (final option in widget.menuList) {
      if (option.userGroups != null &&
          option.userGroups!.contains(
            authBloc.state.authenticate?.user?.userGroup,
          )) {
        menuList.add(option);
        if (targetRoute != null && option.route == targetRoute) {
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
          title: _localizations!.main,
          route: '/',
          child: Container(
            height: 45,
            color: Colors.black,
            child: Center(
              child: Text(
                _localizations!.noAccess,
                style: const TextStyle(color: Colors.red, fontSize: 25),
              ),
            ),
          ),
        ),
        //navigation rail needs at least 2
        MenuOption(
          image: 'packages/growerp_core/images/dashBoardGrey.png',
          selectedImage: 'packages/growerp_core/images/dashBoard.png',
          title: '',
          route: '/',
          child: Container(),
        ),
      ];
      menuIndex = 0;
    }

    // Ensure menuIndex is within bounds
    if (menuIndex >= menuList.length) {
      menuIndex = 0;
    }

    MenuOption menuOption = menuList[menuIndex];
    tabItems = menuOption.tabItems ?? [];
    title = menuOption.title;
    child = menuOption.child;
    tabIndex = widget.tabIndex ?? 0;

    // Initialize displayMOFormKey early to prevent null casting errors
    displayMOFormKey = 'DefaultPage';

    if (tabItems.isEmpty) {
      displayMOFormKey = (child?.toString() ?? '').replaceAll(
        RegExp(r'[^(a-z,A-Z)]'),
        '',
      );
      // Ensure displayMOFormKey is never empty to avoid key conflicts
      if (displayMOFormKey.isEmpty) {
        displayMOFormKey = 'SimplePage';
      }
      // debugPrint("==1== current form key: $displayMOFormKey");
    }
    for (var i = 0; i < tabItems.length; i++) {
      // form key for testing
      String tabFormKey = (tabItems[i].form.toString()).replaceAll(
        RegExp(r'[^(a-z,A-Z)]'),
        '',
      );
      // Ensure tabFormKey is never empty to avoid key conflicts
      if (tabFormKey.isEmpty) {
        tabFormKey = 'Tab$i';
      }
      //debugPrint("==1== current form key: $tabFormKey");
      // form to display
      tabList.add(tabItems[i].form);
      // text of tabs at top of screen (tablet, web)
      tabText.add(
        Align(
          alignment: Alignment.center,
          child: Text(tabItems[i].label, key: Key('tap$tabFormKey')),
        ),
      );
      // tabs at bottom of screen : phone
      bottomItems.add(
        BottomNavigationBarItem(
          icon: tabItems[i].icon,
          label: tabItems[i].label.replaceAll('\n', ' '),
          tooltip: (i + 1).toString(),
        ),
      );
      // floating actionbutton at each tab; not work with domain org
      if (tabItems[i].floatButtonRoute != null) {
        floatingActionButtonList[i] = FloatingActionButton(
          key: const Key("addNew"),
          heroTag: "floatBtn_route_$i",
          onPressed: () async {
            await Navigator.pushReplacementNamed(
              context,
              tabItems[tabIndex].floatButtonRoute!,
              arguments: tabItems[tabIndex].floatButtonArgs,
            );
          },
          tooltip: _localizations!.addNew,
          child: const Icon(Icons.add),
        );
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
              },
            );
          },
          tooltip: _localizations!.addNew,
          child: const Icon(Icons.add),
        );
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      _localizations = CoreLocalizations.of(context)!;
      _initialize(context);
      _isInitialized = true;
    }
    currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    isPhone = isAPhone(context);

    // Safely try to use BlocBuilder, but handle case where ChatRoomBloc is not available
    try {
      return BlocBuilder<ChatRoomBloc, ChatRoomState>(
        builder: (context, state) {
          if (state.status == ChatRoomStatus.success) {
            actions = List.of(widget.actions);
            List<ChatRoom> unReadRooms = state.chatRooms
                .where((element) => element.hasRead == false)
                .toList();
            actions.insert(
              0,
              IconButton(
                key: const Key('chatButton'),
                icon: Badge(
                  label: unReadRooms.isNotEmpty
                      ? Text(unReadRooms.length.toString())
                      : null,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.chat),
                ),
                padding: EdgeInsets.zero,
                tooltip: unReadRooms.isEmpty
                    ? _localizations!.chat
                    : unReadRooms.toString(),
                onPressed: () async => {
                  await showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return const ChatRoomListDialog();
                    },
                  ),
                },
              ),
            );

            if (currentRoute != '/') {
              actions.add(
                IconButton(
                  key: const Key('homeButton'),
                  icon: const Icon(Icons.home),
                  tooltip: _localizations!.goHome,
                  onPressed: () {
                    if (currentRoute.startsWith('/acct')) {
                      Navigator.pushNamed(context, '/accounting');
                    } else {
                      Navigator.pushNamed(context, '/');
                    }
                  },
                ),
              );
            }

            Widget simplePage(bool isPhone) {
              String simplePageFormKey = (child?.toString() ?? '').replaceAll(
                RegExp(r'[^(a-z,A-Z)]'),
                '',
              );
              // Ensure simplePageFormKey is never empty to avoid key conflicts
              if (simplePageFormKey.isEmpty) {
                simplePageFormKey = 'SimplePageChild';
              }
              // debugPrint("==2-simple= current form key: $simplePageFormKey");

              return ScaffoldMessenger(
                child: Scaffold(
                  key: Key(currentRoute),
                  appBar: AppBar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    key: Key(simplePageFormKey),
                    automaticallyImplyLeading: isPhone,
                    leading: leadAction,
                    title: appBarTitle(context, title, isPhone),
                    actions: actions,
                  ),
                  drawer: myDrawer(context, isPhone, menuList),
                  floatingActionButton: floatingActionButton,
                  body: BlocListener<NotificationBloc, NotificationState>(
                    listener: (context, notiFicationState) {
                      if (notiFicationState.status ==
                              NotificationStatus.success &&
                          notiFicationState.notifications.isNotEmpty) {
                        String messages = '';
                        for (final (index, note)
                            in notiFicationState.notifications.indexed) {
                          messages +=
                              "${note.message!["message"]}${index < notiFicationState.notifications.length - 1 ? '\n' : ''}";
                        }
                        HelperFunctions.showMessage(
                          context,
                          messages,
                          Colors.green,
                        );
                      }
                    },
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            }

            Widget tabPage(bool isPhone) {
              String tabPageFormKey =
                  (tabList.isNotEmpty && tabIndex < tabList.length
                          ? tabList[tabIndex].toString()
                          : '')
                      .replaceAll(RegExp(r'[^(a-z,A-Z)]'), '');
              // Ensure tabPageFormKey is never empty to avoid key conflicts
              if (tabPageFormKey.isEmpty) {
                tabPageFormKey = 'TabPage$tabIndex';
              }
              Color tabSelectedBackground = Theme.of(
                context,
              ).colorScheme.onSecondary;
              //debugPrint("==3-tab= current form key: $tabPageFormKey");
              List<Widget> tabChildren = [
                Expanded(
                  child: isPhone
                      ? Center(
                          key: Key(tabPageFormKey),
                          child: tabList[tabIndex],
                        )
                      : TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: _controller,
                          children: tabList,
                        ),
                ),
              ];

              return ScaffoldMessenger(
                child: Scaffold(
                  key: Key(currentRoute),
                  appBar: AppBar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
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
                                topRight: Radius.circular(10),
                              ),
                            ),
                            tabs: tabText,
                          ),
                    title: appBarTitle(
                      context,
                      '$title ${isPhone ? '\n' : ', '}${tabItems[tabIndex].label}',
                      isPhone,
                    ),
                    actions: actions,
                  ),
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
                          },
                        )
                      : null,
                  body: BlocListener<NotificationBloc, NotificationState>(
                    listener: (context, notiFicationState) {
                      if (notiFicationState.status ==
                              NotificationStatus.success &&
                          notiFicationState.notifications.isNotEmpty) {
                        String messages = '';
                        for (final (index, note)
                            in notiFicationState.notifications.indexed) {
                          messages +=
                              "${note.message!["message"]}${index < notiFicationState.notifications.length - 1 ? '\n' : ''}";
                        }
                        HelperFunctions.showMessage(
                          context,
                          messages,
                          Colors.green,
                        );
                      }
                    },
                    child: Column(children: tabChildren),
                  ),
                ),
              );
            }

            if ((!kReleaseMode ||
                GlobalConfiguration().get("test") &&
                    // app store not accept banner
                    !Platform.isIOS &&
                    !Platform.isMacOS)) {
              return Banner(
                message: _localizations!.test,
                color: Colors.red,
                location: BannerLocation.topStart,
                child: showPage(simplePage, context, tabPage),
              );
            } else {
              return showPage(simplePage, context, tabPage);
            }
          } else {
            return const Center(child: LoadingIndicator());
          }
        },
      );
    } catch (e) {
      // ChatRoomBloc not available, render without it
      actions = List.of(widget.actions);
      if (currentRoute != '/') {
        actions.add(
          IconButton(
            key: const Key('homeButton'),
            icon: const Icon(Icons.home),
            tooltip: _localizations!.goHome,
            onPressed: () {
              if (currentRoute.startsWith('/acct')) {
                Navigator.pushNamed(context, '/accounting');
              } else {
                Navigator.pushNamed(context, '/');
              }
            },
          ),
        );
      }

      // Return minimal content without chat
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          automaticallyImplyLeading: isPhone,
          leading: leadAction,
          title: appBarTitle(context, title, isPhone),
          actions: actions,
        ),
        drawer: myDrawer(context, isPhone, menuList),
        floatingActionButton: floatingActionButton,
        body: child ?? const SizedBox(),
      );
    }
  }

  Widget showPage(
    Widget Function(bool isPhone) simplePage,
    BuildContext context,
    Widget Function(bool isPhone) tabPage,
  ) {
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
        return myNavigationRail(context, tabPage(isPhone), menuIndex, menuList);
      }
    }
  }
}
