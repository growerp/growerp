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

/// DisplayMenuItem - Renders menu-based navigation with GoRouter
///
/// This widget handles:
/// - Menu rendering (simple pages vs tabbed pages)
/// - Navigation via GoRouter
/// - Chat integration
/// - Notification handling
/// - Drawer and navigation rail integration
/// - Security filtering by user groups
class DisplayMenuItem extends StatefulWidget {
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

  const DisplayMenuItem({
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
  DisplayMenuItemState createState() => DisplayMenuItemState();
}

class DisplayMenuItemState extends State<DisplayMenuItem>
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
  List<MenuItem> menuList = [];
  int menuIndex = 0;
  CoreLocalizations? _localizations;
  bool _isInitialized = false;
  MenuConfiguration? _lastMenuConfig;

  @override
  void initState() {
    super.initState();
    // Trigger chat room fetch after first frame if already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerChatRoomFetchIfNeeded();
    });
  }

  void _triggerChatRoomFetchIfNeeded() {
    try {
      final authBloc = context.read<AuthBloc>();
      final chatBloc = context.read<ChatRoomBloc>();
      if (authBloc.state.status == AuthStatus.authenticated) {
        // Always refresh to ensure we have fresh data after login
        chatBloc.add(const ChatRoomFetch(refresh: true));
      }
    } catch (e) {
      // Blocs not available, ignore
    }
  }

  @override
  void didUpdateWidget(DisplayMenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menuIndex != oldWidget.menuIndex ||
        widget.menuConfiguration != oldWidget.menuConfiguration) {
      _initialize(context, widget.menuConfiguration);
    }
  }

  void _initialize(BuildContext context, MenuConfiguration menuConfiguration) {
    authBloc = context.read<AuthBloc>();

    // Get the target menu option
    MenuItem? targetOption;

    if (widget.menuIndex >= 0 &&
        widget.menuIndex < menuConfiguration.menuItems.length) {
      targetOption = menuConfiguration.menuItems[widget.menuIndex];
    }

    // Filter menu options: Keep only accessible AND active items
    int newIndex = 0;
    menuList = [];

    for (final option in menuConfiguration.menuItems) {
      // Only add if user has access AND it's active
      if (_hasAccess(option) && option.isActive) {
        menuList.add(option);

        // Check if this is the item we should highlight
        // Use menuItemId if available, otherwise fall back to route or itemKey
        if (targetOption != null) {
          bool isMatch = false;
          if (option.menuItemId != null && targetOption.menuItemId != null) {
            isMatch = option.menuItemId == targetOption.menuItemId;
          } else if (option.route != null && targetOption.route != null) {
            isMatch = option.route == targetOption.route;
          } else if (option.itemKey != null && targetOption.itemKey != null) {
            isMatch = option.itemKey == targetOption.itemKey;
          }
          if (isMatch) {
            menuIndex = newIndex;
          }
        }
        newIndex++;
      }
    }

    // Fallback if no menu options accessible
    if (menuList.isEmpty) {
      menuList = [
        MenuItem(
          menuItemId: 'no-access',
          menuConfigurationId: menuConfiguration.menuConfigurationId,
          title: _localizations!.noAccess,
          route: '/',
          iconName: 'dashboard',
          sequenceNum: 0,
          isActive: true,
        ),
        // Navigation rail needs at least 2 items
        MenuItem(
          menuItemId: 'no-access-2',
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

    MenuItem menuOption = menuList[menuIndex];

    // Get child menu items (tabs) from the option's children
    tabItems =
        (menuOption.children ?? [])
            .where((item) => item.isActive && _hasAccessToItem(item))
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

    title = HelperFunctions.translateMenuTitle(
      _localizations!,
      menuOption.title,
    );

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

  bool _hasAccess(MenuItem option) {
    if (option.userGroups == null || option.userGroups!.isEmpty) {
      return true; // No restrictions
    }
    return option.userGroups!.contains(
      authBloc.state.authenticate?.user?.userGroup,
    );
  }

  bool _hasAccessToItem(MenuItem item) {
    // MenuItems don't have userGroups in the new model
    // Access is controlled at the MenuItem level
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

          // If config is still null (shouldn't happen), return error message
          // Don't use CircularProgressIndicator as it prevents pumpAndSettle in tests
          if (menuConfiguration == null) {
            return Center(
              child: Text(
                'Menu configuration not available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
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
      return MultiBlocListener(
        listeners: [
          // Note: Auth messages (login, logout, errors) are now handled
          // at the TopApp level with retry logic for scaffold availability
          // Listener for authentication status changes
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != AuthStatus.authenticated &&
                current.status == AuthStatus.authenticated,
            listener: (context, authState) async {
              // Trigger chat room fetch when user becomes authenticated
              // Always refresh to get fresh data after login
              context.read<ChatRoomBloc>().add(
                const ChatRoomFetch(refresh: true),
              );

              // Note: Trial welcome dialog is now shown in TenantSetupDialog
              // before the user reaches the main menu

              // Show subscription expiration warning (last 3 days, once per day)
              // Uses consolidated helper for cleaner code
              await SubscriptionWarningHelper.showWarningIfNeeded(
                context: context,
                authenticate: authState.authenticate,
                onSubscribeNow: () {
                  // Navigate to subscription management
                  // context.go('/subscription');
                },
              );
            },
          ),
        ],
        child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
          builder: (context, chatState) {
            // Always build the page, show chat badge when data is available
            if (chatState.status == ChatRoomStatus.success) {
              _buildActions(chatState);
            } else {
              _buildActions(null);
            }
            return _buildPage();
          },
        ),
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
    if (GlobalConfiguration().get("test") &&
        !Platform.isIOS &&
        !Platform.isMacOS) {
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
          : ScaffoldMessenger(
              child: myNavigationRail(
                context,
                _buildSimplePage(wrapInScaffoldMessenger: false),
                menuIndex,
                menuList,
              ),
            );
    } else {
      // Tabbed page
      return isPhone
          ? _buildTabbedPage()
          : ScaffoldMessenger(
              child: myNavigationRail(
                context,
                _buildTabbedPage(wrapInScaffoldMessenger: false),
                menuIndex,
                menuList,
              ),
            );
    }
  }

  Widget _buildSimplePage({bool wrapInScaffoldMessenger = true}) {
    final scaffold = Scaffold(
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
        child: Column(
          children: [
            Expanded(child: widget.child ?? const SizedBox.shrink()),
            // Hidden API key and session token for integration testing
            _buildHiddenTestWidgets(),
          ],
        ),
      ),
    );
    return wrapInScaffoldMessenger
        ? ScaffoldMessenger(child: scaffold)
        : scaffold;
  }

  Widget _buildTabbedPage({bool wrapInScaffoldMessenger = true}) {
    Color tabSelectedBackground = Theme.of(context).colorScheme.onSecondary;

    final scaffold = Scaffold(
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
                          text: HelperFunctions.translateMenuTitle(
                            _localizations!,
                            item.title,
                          ),
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
      bottomNavigationBar: isPhone && tabItems.length >= 2
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: tabItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon:
                          getIconFromRegistry(item.iconName) ??
                          const Icon(Icons.circle),
                      label: HelperFunctions.translateMenuTitle(
                        _localizations!,
                        item.title,
                      ).replaceAll('\n', ' '),
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
        child: Column(
          children: [
            Expanded(
              child: isPhone
                  ? (widget.tabWidgetLoader != null &&
                            tabItems.isNotEmpty &&
                            tabIndex < tabItems.length
                        ? widget.tabWidgetLoader!(
                            tabItems[tabIndex].widgetName ?? 'Unknown',
                            {},
                          )
                        : (widget.child ?? const SizedBox.shrink()))
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
            // Hidden API key and session token for integration testing
            _buildHiddenTestWidgets(),
          ],
        ),
      ),
    );
    return wrapInScaffoldMessenger
        ? ScaffoldMessenger(child: scaffold)
        : scaffold;
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

  /// Build hidden widgets for integration testing
  /// These display API key and session token with font size 0
  /// so they're accessible to WidgetTester but invisible to users
  Widget _buildHiddenTestWidgets() {
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    final authenticate = authBloc.state.authenticate;
    if (authenticate?.apiKey == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          authenticate!.apiKey!,
          key: const Key('apiKey'),
          style: const TextStyle(fontSize: 0),
        ),
        if (authenticate.moquiSessionToken != null)
          Text(
            authenticate.moquiSessionToken!,
            key: const Key('moquiSessionToken'),
            style: const TextStyle(fontSize: 0),
          ),
      ],
    );
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
