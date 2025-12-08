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
import 'package:go_router/go_router.dart';
import 'package:growerp_chat/growerp_chat.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:universal_io/io.dart';
import '../../growerp_core.dart';

/// DisplayMenuOption - Renders menu-based navigation with GoRouter
///
/// This widget handles:
/// - Menu rendering (simple pages vs tabbed pages)
/// - Navigation via GoRouter
/// - Chat integration
/// - Notification handling
/// - Drawer and navigation rail integration
/// - Security filtering by user groups
class DisplayMenuOption extends StatefulWidget {
  final MenuConfiguration menuConfiguration;
  final int menuIndex;
  final int? tabIndex;
  final List<Widget> actions;
  final Widget? child; // Optional child widget for page content
  final Widget Function(String widgetName, Map<String, dynamic> args)?
  tabWidgetLoader;
  final bool suppressBlocMenuConfig;

  /// Optional floating action button to display above the AI FAB
  final Widget? floatingActionButton;

  /// Optional Gemini API key for AI navigation
  final String? aiApiKey;

  const DisplayMenuOption({
    super.key,
    required this.menuConfiguration,
    required this.menuIndex,
    this.tabIndex,
    this.actions = const [],
    this.child,
    this.tabWidgetLoader,
    this.suppressBlocMenuConfig = false,
    this.floatingActionButton,
    this.aiApiKey,
  });

  @override
  DisplayMenuOptionState createState() => DisplayMenuOptionState();
}

class DisplayMenuOptionState extends State<DisplayMenuOption>
    with TickerProviderStateMixin {
  late int tabIndex;
  List<MenuItem> tabItems = [];
  late String title;
  List<Widget> actions = [];
  Widget? leadAction;
  TabController? _controller;
  String currentRoute = '';
  late bool isPhone;
  late AuthBloc authBloc;
  List<MenuOption> menuList = [];
  int menuIndex = 0;
  CoreLocalizations? _localizations;
  bool _isInitialized = false;
  MenuConfiguration? _lastMenuConfig;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(DisplayMenuOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menuIndex != oldWidget.menuIndex ||
        widget.menuConfiguration != oldWidget.menuConfiguration) {
      _initialize(context, widget.menuConfiguration);
    }
  }

  void _initialize(BuildContext context, MenuConfiguration menuConfiguration) {
    authBloc = context.read<AuthBloc>();

    // Get the target menu option
    MenuOption? targetOption;

    if (widget.menuIndex >= 0 &&
        widget.menuIndex < menuConfiguration.menuOptions.length) {
      targetOption = menuConfiguration.menuOptions[widget.menuIndex];
    }

    // Filter menu options: Keep only accessible AND active items
    int newIndex = 0;
    menuList = [];

    for (final option in menuConfiguration.menuOptions) {
      // Only add if user has access AND it's active
      if (_hasAccess(option) && option.isActive) {
        menuList.add(option);

        // Check if this is the item we should highlight
        if (targetOption != null &&
            option.menuOptionId == targetOption.menuOptionId) {
          menuIndex = newIndex;
        }
        newIndex++;
      }
    }

    // Fallback if no menu options accessible
    if (menuList.isEmpty) {
      menuList = [
        MenuOption(
          menuOptionId: 'no-access',
          menuConfigurationId: menuConfiguration.menuConfigurationId,
          title: _localizations!.noAccess,
          route: '/',
          iconName: 'dashboard',
          sequenceNum: 0,
          isActive: true,
        ),
        // Navigation rail needs at least 2 items
        MenuOption(
          menuOptionId: 'no-access-2',
          menuConfigurationId: menuConfiguration.menuConfigurationId,
          title: '',
          route: '/',
          iconName: 'dashboard',
          sequenceNum: 1,
          isActive: true,
        ),
      ];
      menuIndex = 0;
    }

    // Ensure menuIndex is within bounds
    if (menuIndex >= menuList.length) {
      menuIndex = 0;
    }

    MenuOption menuOption = menuList[menuIndex];

    // Get child menu items (tabs) from the option's children
    tabItems =
        (menuOption.children ?? [])
            .where((item) => item.isActive && _hasAccessToItem(item))
            .toList()
          ..sort((a, b) => (a.sequenceNum ?? 0).compareTo(b.sequenceNum ?? 0));

    title = menuOption.title;

    // Determine the initial tab index
    tabIndex = widget.tabIndex ?? 0;

    // Initialize tab controller if we have tabs
    if (tabItems.isNotEmpty) {
      _controller?.dispose();
      _controller = TabController(
        length: tabItems.length,
        vsync: this,
        initialIndex: tabIndex.clamp(0, tabItems.length - 1),
      );
      _controller!.addListener(() {
        setState(() {
          tabIndex = _controller!.index;
        });
      });
    }
  }

  bool _hasAccess(MenuOption option) {
    if (option.userGroups == null || option.userGroups!.isEmpty) {
      return true; // No restrictions
    }
    return option.userGroups!.contains(
      authBloc.state.authenticate?.user?.userGroup,
    );
  }

  bool _hasAccessToItem(MenuItem item) {
    // MenuItems don't have userGroups in the new model
    // Access is controlled at the MenuOption level
    return true;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    currentRoute = GoRouterState.of(context).uri.toString();
    isPhone = isAPhone(context);

    // Check if MenuConfigBloc is available in the widget tree
    final menuConfigBloc = context.read<MenuConfigBloc?>();

    if (menuConfigBloc != null) {
      // Listen to MenuConfigBloc for menu updates
      return BlocBuilder<MenuConfigBloc, MenuConfigState>(
        buildWhen: (previous, current) {
          // Only rebuild when menu configuration changes
          return previous.menuConfiguration != current.menuConfiguration;
        },
        builder: (context, menuConfigState) {
          // Use bloc state if available (and not suppressed), otherwise use widget's initial configuration
          final menuConfiguration =
              (!widget.suppressBlocMenuConfig &&
                  menuConfigState.menuConfiguration != null)
              ? menuConfigState.menuConfiguration
              : widget.menuConfiguration;

          // If config is still null (shouldn't happen), return loading/empty
          if (menuConfiguration == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Force using the passed configuration if it's different (e.g. for sub-menus)
          // AND we are suppressing the global config
          final effectiveConfig = widget.suppressBlocMenuConfig
              ? widget.menuConfiguration
              : menuConfiguration;

          if (!_isInitialized || effectiveConfig != _lastMenuConfig) {
            _localizations = CoreLocalizations.of(context)!;
            _initialize(context, effectiveConfig);
            _isInitialized = true;
            _lastMenuConfig = effectiveConfig;
          }

          return _buildWithChatBloc();
        },
      );
    } else {
      // MenuConfigBloc not available - use static configuration from widget
      if (!_isInitialized) {
        _localizations = CoreLocalizations.of(context)!;
        _initialize(context, widget.menuConfiguration);
        _isInitialized = true;
      }
      return _buildWithChatBloc();
    }
  }

  Widget _buildWithChatBloc() {
    // Try to use BlocBuilder for chat, fallback if not available
    try {
      return BlocBuilder<ChatRoomBloc, ChatRoomState>(
        builder: (context, state) {
          if (state.status == ChatRoomStatus.success) {
            _buildActions(state);
            return _buildPage();
          } else {
            return const Center(child: LoadingIndicator());
          }
        },
      );
    } catch (e) {
      // ChatRoomBloc not available, render without it
      _buildActions(null);
      return _buildPage();
    }
  }

  void _buildActions(ChatRoomState? chatState) {
    actions = List.of(widget.actions);

    // Add chat button if chat is available
    if (chatState != null) {
      List<ChatRoom> unReadRooms = chatState.chatRooms
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
    }

    // Add home button if not on home route
    if (currentRoute != '/') {
      actions.add(
        IconButton(
          key: const Key('homeButton'),
          icon: const Icon(Icons.home),
          tooltip: _localizations!.goHome,
          onPressed: () {
            if (currentRoute.startsWith('/accounting') &&
                currentRoute != '/accounting') {
              context.go('/accounting');
            } else {
              context.go('/');
            }
          },
        ),
      );
    }
  }

  Widget _buildPage() {
    if ((!kReleaseMode ||
        GlobalConfiguration().get("test") &&
            !Platform.isIOS &&
            !Platform.isMacOS)) {
      return Banner(
        message: _localizations!.test,
        color: Colors.red,
        location: BannerLocation.topStart,
        child: _showPage(),
      );
    } else {
      return _showPage();
    }
  }

  Widget _showPage() {
    if (tabItems.isEmpty) {
      // Simple page (no tabs)
      return isPhone
          ? _buildSimplePage()
          : myNavigationRail(context, _buildSimplePage(), menuIndex, menuList);
    } else {
      // Tabbed page
      return isPhone
          ? _buildTabbedPage()
          : myNavigationRail(context, _buildTabbedPage(), menuIndex, menuList);
    }
  }

  Widget _buildSimplePage() {
    return ScaffoldMessenger(
      child: Scaffold(
        key: Key(currentRoute),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          key: Key('appBar_$currentRoute'),
          automaticallyImplyLeading: isPhone,
          leading: leadAction,
          title: appBarTitle(context, title, isPhone),
          actions: actions,
        ),
        drawer: myDrawer(context, isPhone, menuList),
        floatingActionButton: _buildAiFab(),
        body: BlocListener<NotificationBloc, NotificationState>(
          listener: _handleNotifications,
          child: widget.child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildTabbedPage() {
    Color tabSelectedBackground = Theme.of(context).colorScheme.onSecondary;

    return ScaffoldMessenger(
      child: Scaffold(
        key: Key(currentRoute),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          automaticallyImplyLeading: isPhone,
          bottom: isPhone
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(30.0),
                  child: TabBar(
                    controller: _controller,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: tabSelectedBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    tabs: tabItems
                        .map(
                          (item) => Tab(
                            height: 30,
                            key: Key('tab_${item.menuItemId}'),
                            text: item.title,
                          ),
                        )
                        .toList(),
                    onTap: (index) {
                      // Navigate using widget name via router
                      if (index < tabItems.length) {
                        final option = menuList[menuIndex];
                        // For tabs, use the parent option route
                        final baseRoute = option.route ?? '/';
                        context.go(baseRoute);
                      }
                    },
                  ),
                ),
          title: appBarTitle(
            context,
            '$title ${isPhone ? '\n' : ', '}${tabItems.isNotEmpty && tabIndex < tabItems.length ? tabItems[tabIndex].title : ''}',
            isPhone,
          ),
          actions: actions,
        ),
        drawer: myDrawer(context, isPhone, menuList),
        bottomNavigationBar: isPhone
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: tabItems
                    .map(
                      (item) => BottomNavigationBarItem(
                        icon:
                            getIconFromRegistry(item.iconName) ??
                            const Icon(Icons.circle),
                        label: item.title.replaceAll('\n', ' '),
                      ),
                    )
                    .toList(),
                currentIndex: tabIndex,
                selectedItemColor: Colors.amber[800],
                onTap: (index) {
                  setState(() {
                    tabIndex = index;
                    _controller?.animateTo(index);
                  });
                },
              )
            : null,
        floatingActionButton: _buildAiFab(),
        body: BlocListener<NotificationBloc, NotificationState>(
          listener: _handleNotifications,
          child: isPhone
              ? (widget.child ?? const SizedBox.shrink())
              : TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _controller,
                  children: List.generate(tabItems.length, (index) {
                    if (widget.tabWidgetLoader != null) {
                      return widget.tabWidgetLoader!(
                        tabItems[index].widgetName ?? 'Unknown',
                        {},
                      );
                    }
                    return widget.child ?? const SizedBox.shrink();
                  }),
                ),
        ),
      ),
    );
  }

  /// Build AI FAB button (and optional additional FAB above it)
  Widget? _buildAiFab() {
    final aiFab = FloatingActionButton(
      key: const Key('aiFab'),
      heroTag: 'aiFab',
      mini: true,
      tooltip: 'AI Navigation',
      onPressed: () async {
        // Load API key from SharedPreferences
        final apiKey = await SystemSetupDialog.getGeminiApiKey() ?? '';
        if (!mounted) return;

        AiPromptDialog.show(
          context,
          apiKey: apiKey,
          menuConfiguration: widget.menuConfiguration,
          onNavigate: (intent) {
            // Use route from intent if available, otherwise derive from widget name
            if (intent.route != null && intent.route!.isNotEmpty) {
              context.go(intent.route!);
            } else {
              final route = intent.widgetName
                  .replaceAllMapped(
                    RegExp(r'([A-Z])'),
                    (m) => '-${m.group(1)!.toLowerCase()}',
                  )
                  .substring(1); // Remove leading dash
              context.go('/$route');
            }
          },
        );
      },
      child: const Icon(Icons.psychology),
    );

    // If there's an additional FAB, stack it above the AI FAB
    if (widget.floatingActionButton != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.floatingActionButton!,
          const SizedBox(height: 12),
          aiFab,
        ],
      );
    }

    return aiFab;
  }

  void _handleNotifications(BuildContext context, NotificationState state) {
    if (state.status == NotificationStatus.success &&
        state.notifications.isNotEmpty) {
      String messages = '';
      for (final (index, note) in state.notifications.indexed) {
        messages +=
            "${note.message!["message"]}${index < state.notifications.length - 1 ? '\n' : ''}";
      }
      HelperFunctions.showMessage(context, messages, Colors.green);
    }
  }
}
