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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../get_core_bloc_providers.dart';
import '../../../services/widget_registry.dart';
import '../../../services/ws_client.dart';
import '../../../styles/color_schemes.dart';
import '../../domains.dart';
import 'package:growerp_core/l10n/generated/core_localizations.dart';

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
    for (final widgetMap in widget.widgetRegistrations) {
      WidgetRegistry.register(widgetMap);
    }
    if (widget.appId != null) {
      _menuConfigBloc = MenuConfigBloc(widget.restClient, widget.appId!);
    }
  }

  @override
  void dispose() {
    _menuConfigBloc?.close();
    super.dispose();
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
                return GestureDetector(
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
                    builder: (context, child) => ResponsiveBreakpoints.builder(
                      child: child!,
                      breakpoints: [
                        const Breakpoint(start: 0, end: 500, name: MOBILE),
                        const Breakpoint(start: 451, end: 800, name: TABLET),
                        const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                        const Breakpoint(
                          start: 1921,
                          end: double.infinity,
                          name: '4K',
                        ),
                      ],
                    ),
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
                        inputDecoratorBorderType: FlexInputBorderType.underline,
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
                          TargetPlatform
                              .android: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform
                              .linux: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform
                              .macOS: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform
                              .windows: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
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
                        inputDecoratorBorderType: FlexInputBorderType.underline,
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
                          TargetPlatform
                              .android: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform
                              .linux: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform
                              .macOS: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                          TargetPlatform
                              .windows: SharedAxisPageTransitionsBuilder(
                            transitionType: SharedAxisTransitionType.horizontal,
                          ),
                        },
                      ),
                    ),
                    routerConfig: widget.router,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
