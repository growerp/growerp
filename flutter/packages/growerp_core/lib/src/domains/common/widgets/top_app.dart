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

import 'package:animations/animations.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';

import '../../../get_core_bloc_providers.dart';
import '../../../services/widget_registry.dart';
import '../../../services/ws_client.dart';
import '../../../styles/color_schemes.dart';
import '../../domains.dart';

/// TopApp is the main application wrapper that provides all core functionality.
class TopApp extends StatefulWidget {
  const TopApp({
    super.key,
    required this.restClient,
    required this.classificationId,
    required this.chatClient,
    required this.notificationClient,
    this.title = '',
    required this.router,
    this.extraDelegates = const [],
    this.extraBlocProviders = const [],
    this.company,
    this.appId,
    this.widgetRegistrations = const [],
    this.forceUpdateInfo,
  });

  final RestClient restClient;
  final String classificationId;
  final Company? company;

  final WsClient chatClient;
  final WsClient notificationClient;
  final String title;
  final GoRouter router;

  final List<LocalizationsDelegate> extraDelegates;
  final List<BlocProvider> extraBlocProviders;

  final String? appId;
  final List<Map<String, GrowerpWidgetBuilder>> widgetRegistrations;

  /// Force update information from backend. If provided and forceUpdate is true,
  /// a non-dismissible dialog will be shown prompting the user to update.
  final ForceUpdateInfo? forceUpdateInfo;

  @override
  State<TopApp> createState() => _TopAppState();
}

class _TopAppState extends State<TopApp> {
  MenuConfigBloc? _menuConfigBloc;

  final List<LocalizationsDelegate> _localizationsDelegates = [
    CoreLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  void initState() {
    super.initState();

    // Hide Android system navigation bar (bottom bar) for immersive experience
    // immersiveSticky mode hides bars but allows temporary access via edge swipe
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top], // Keep status bar, hide navigation bar
    );

    for (final widgetMap in widget.widgetRegistrations) {
      WidgetRegistry.register(widgetMap);
    }
    if (widget.appId != null) {
      _menuConfigBloc = MenuConfigBloc(widget.restClient, widget.appId!);
    }
  }

  @override
  void dispose() {
    // Close WebSocket connections gracefully to avoid backend ClosedChannelException
    widget.chatClient.close();
    widget.notificationClient.close();
    _menuConfigBloc?.close();
    super.dispose();
  }

  /// Shows a snackbar message with retry logic to wait for scaffold messenger
  /// to become available after navigation transitions
  void _showMessageWithRetry(String message, bool isError, [int attempt = 0]) {
    final messenger = Constant.scaffoldMessengerKey.currentState;
    if (messenger != null) {
      // Use neutral colors that work in both light and dark modes
      // Avoid context.read() as it may fail during navigation transitions
      final backgroundColor = isError
          ? Colors.red.shade700
          : Colors.blueGrey.shade700;
      const textColor = Colors.white;
      final duration = Duration(milliseconds: isError ? 5000 : 2000);

      try {
        // Hide any existing snackbar first
        try {
          messenger.hideCurrentSnackBar();
        } catch (_) {}

        final controller = messenger.showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(message, style: const TextStyle(color: textColor)),
            backgroundColor: backgroundColor,
            duration: duration,
            action: SnackBarAction(
              key: const Key('dismiss'),
              label: 'Dismiss',
              textColor: textColor.withValues(alpha: 0.8),
              onPressed: () => messenger.hideCurrentSnackBar(),
            ),
          ),
        );

        // Ensure snackbar disappears even if accessibility keeps it alive
        var isClosed = false;
        controller.closed.whenComplete(() => isClosed = true);
        Future.delayed(duration + const Duration(milliseconds: 500), () {
          if (!isClosed) {
            try {
              controller.close();
            } catch (_) {}
          }
        });
      } catch (e) {
        // Scaffold not yet in tree or messenger disposed, retry
        if (attempt < 10) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _showMessageWithRetry(message, isError, attempt + 1);
            }
          });
        } else {
          // Give up silently - message will not be shown if Scaffold is unavailable
          // during app initialization. This is safe behavior.
          debugPrint('SnackBar not shown - Scaffold unavailable: $message');
        }
      }
    } else if (attempt < 10) {
      // Retry after a short delay (scaffold messenger not ready yet)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _showMessageWithRetry(message, isError, attempt + 1);
        }
      });
    } else {
      // Give up after 10 attempts (1s total) - this is safe, message just won't display
      // if Scaffold is never available, which shouldn't happen in normal operation
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => widget.restClient),
        RepositoryProvider(create: (context) => widget.chatClient),
        RepositoryProvider(create: (context) => widget.notificationClient),
        RepositoryProvider(create: (context) => widget.classificationId),
        RepositoryProvider(create: (context) => widget.company),
      ],
      child: MultiBlocProvider(
        providers: [
          ...getCoreBlocProviders(
            widget.restClient,
            widget.chatClient,
            widget.notificationClient,
            widget.classificationId,
            widget.company,
          ),
          if (_menuConfigBloc != null)
            BlocProvider<MenuConfigBloc>.value(value: _menuConfigBloc!),
          ...widget.extraBlocProviders,
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            _localizationsDelegates.addAll(widget.extraDelegates);
            return BlocBuilder<LocaleBloc, LocaleState>(
              builder: (context, localeState) {
                return BlocListener<AuthBloc, AuthState>(
                  listenWhen: (previous, current) =>
                      current.message != null &&
                      previous.message != current.message,
                  listener: (context, authState) {
                    if (authState.message != null &&
                        authState.message!.isNotEmpty) {
                      final isError = authState.status == AuthStatus.failure;
                      final message = authState.message!;
                      // Use a retry mechanism to wait for scaffold messenger
                      // to become available after navigation
                      _showMessageWithRetry(message, isError);
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      FocusScopeNode currentFocus = FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: MaterialApp.router(
                      scaffoldMessengerKey: Constant.scaffoldMessengerKey,
                      title: widget.title,
                      locale: localeState.locale,
                      supportedLocales: const [
                        Locale('en'),
                        Locale('th'),
                        Locale('zh'),
                        Locale('de'),
                        Locale('fr'),
                        Locale('nl'),
                      ],
                      scrollBehavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.touch,
                        },
                      ),
                      debugShowCheckedModeBanner: false,
                      localizationsDelegates: _localizationsDelegates,
                      builder: (context, child) {
                        Widget appContent = ResponsiveBreakpoints.builder(
                          child: child!,
                          breakpoints: [
                            const Breakpoint(start: 0, end: 500, name: MOBILE),
                            const Breakpoint(
                              start: 451,
                              end: 800,
                              name: TABLET,
                            ),
                            const Breakpoint(
                              start: 801,
                              end: 1920,
                              name: DESKTOP,
                            ),
                            const Breakpoint(
                              start: 1921,
                              end: double.infinity,
                              name: '4K',
                            ),
                          ],
                        );

                        // If force update is required, show blocking overlay
                        if (widget.forceUpdateInfo != null &&
                            widget.forceUpdateInfo!.forceUpdate) {
                          return Scaffold(
                            body: Stack(
                              children: [
                                appContent,
                                // Full-screen blocking overlay
                                Positioned.fill(
                                  child: ForceUpdateScreen(
                                    forceUpdateInfo: widget.forceUpdateInfo!,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Scaffold(body: appContent);
                      },
                      themeMode: themeState.themeMode,
                      theme: FlexThemeData.light(
                        colors: themeState.colorScheme == FlexScheme.jungle
                            ? growerpPremium.light
                            : null,
                        scheme: themeState.colorScheme,
                        fontFamily: GoogleFonts.outfit().fontFamily,
                        blendLevel: 10,
                        subThemesData: const FlexSubThemesData(
                          blendOnLevel: 10,
                          blendOnColors: false,
                          useM2StyleDividerInM3: true,
                          dialogBackgroundSchemeColor: SchemeColor.surface,
                          inputDecoratorBorderType:
                              FlexInputBorderType.underline,
                          inputDecoratorRadius: 25.0,
                          defaultRadius: 25.0,
                          useInputDecoratorThemeInDialogs: true,
                          cardElevation: 2,
                          dialogElevation: 3,
                        ),
                        useMaterial3: true,
                        visualDensity: VisualDensity.adaptivePlatformDensity,
                        pageTransitionsTheme: const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.iOS:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.linux:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.macOS:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.windows:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                          },
                        ),
                      ),
                      darkTheme: FlexThemeData.dark(
                        colors: themeState.colorScheme == FlexScheme.jungle
                            ? growerpPremium.dark
                            : null,
                        scheme: themeState.colorScheme,
                        fontFamily: GoogleFonts.outfit().fontFamily,
                        blendLevel: 13,
                        subThemesData: const FlexSubThemesData(
                          blendOnLevel: 20,
                          useM2StyleDividerInM3: true,
                          dialogBackgroundSchemeColor: SchemeColor.surface,
                          inputDecoratorBorderType:
                              FlexInputBorderType.underline,
                          inputDecoratorRadius: 25.0,
                          defaultRadius: 25.0,
                          useInputDecoratorThemeInDialogs: true,
                          cardElevation: 2,
                          dialogElevation: 3,
                        ),
                        useMaterial3: true,
                        visualDensity: VisualDensity.adaptivePlatformDensity,
                        pageTransitionsTheme: const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.iOS:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.linux:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.macOS:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                            TargetPlatform.windows:
                                SharedAxisPageTransitionsBuilder(
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                ),
                          },
                        ),
                      ),
                      routerConfig: widget.router,
                    ),
                  ), // Close GestureDetector
                ); // Close BlocListener
              },
            );
          },
        ),
      ),
    );
  }
}
