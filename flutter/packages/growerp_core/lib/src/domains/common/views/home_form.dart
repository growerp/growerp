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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:universal_io/io.dart';

import 'package:growerp_core/l10n/generated/core_localizations.dart';
import '../../domains.dart';

/// Premium home screen with animated gradient background, entrance animations,
/// and a polished hero section for a compelling first impression.
class HomeForm extends StatefulWidget {
  final MenuConfiguration menuConfiguration;
  final String title;
  final String? launcherImage;

  const HomeForm({
    super.key,
    required this.menuConfiguration,
    this.title = "",
    this.launcherImage,
  });

  @override
  HomeFormState createState() => HomeFormState();
}

class HomeFormState extends State<HomeForm> with TickerProviderStateMixin {
  late AuthBloc _authBloc;
  Company? company;
  late String classificationId;
  CoreLocalizations? _localizations;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    company = context.read<Company?>();
    classificationId = context.read<String>();

    // Setup entrance animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    // Note: Auth messages (including logout) are now handled at TopApp level
    // with retry logic to ensure scaffold messenger is available
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = CoreLocalizations.of(context);
    bool isPhone = isAPhone(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget appInfo = Center(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surface.withValues(alpha: 0.7),
          ),
          child: GlobalConfiguration().get("appName") != ''
              ? Text(
                  "GrowERP "
                  "${GlobalConfiguration().get("appName")} "
                  "V${GlobalConfiguration().get("version")} "
                  "#${GlobalConfiguration().get("build")}",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  'GrowERP',
                  style: TextStyle(color: colorScheme.outline, fontSize: 11),
                ),
        ),
      ),
    );

    Widget content = BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state.status) {
          case AuthStatus.failure:
            HelperFunctions.showMessage(
              context,
              '${state.message}',
              Theme.of(context).colorScheme.error,
            );
          default:
            HelperFunctions.showMessage(
              context,
              state.message,
              Theme.of(context).colorScheme.primary,
            );
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
            return const Text(
              "should never show because this form is only used for non authenticated",
            );
          case AuthStatus.failure:
          case AuthStatus.unAuthenticated:
            ThemeMode? themeMode = context.read<ThemeBloc>().state.themeMode;
            return Container(
              decoration: BoxDecoration(
                // Animated gradient background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.primaryContainer.withValues(
                      alpha: isDark ? 0.2 : 0.15,
                    ),
                    colorScheme.secondaryContainer.withValues(
                      alpha: isDark ? 0.15 : 0.1,
                    ),
                    colorScheme.surface,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.9),
                        elevation: 0,
                        key: const Key('HomeFormUnAuth'),
                        title: Center(
                          child: Text(
                            _localizations!.welcomeToGrowERPBusinessSystem,
                            style: TextStyle(
                              fontSize: isPhone ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        actions: [
                          PopupMenuButton<Locale>(
                            key: const Key('languageSelector'),
                            icon: Icon(
                              Icons.language,
                              color: colorScheme.onSurface,
                            ),
                            tooltip: _localizations!.selectLanguage,
                            onSelected: (Locale locale) {
                              context.read<LocaleBloc>().add(
                                LocaleChanged(locale),
                              );
                            },
                            itemBuilder: (BuildContext context) => [
                              _buildLanguageMenuItem(
                                const Locale('en'),
                                '🇺🇸',
                                'English',
                              ),
                              _buildLanguageMenuItem(
                                const Locale('th'),
                                '🇹🇭',
                                'ไทย',
                              ),
                              _buildLanguageMenuItem(
                                const Locale('zh'),
                                '🇨🇳',
                                '中文',
                              ),
                              _buildLanguageMenuItem(
                                const Locale('de'),
                                '🇩🇪',
                                'Deutsch',
                              ),
                              _buildLanguageMenuItem(
                                const Locale('fr'),
                                '🇫🇷',
                                'Français',
                              ),
                              _buildLanguageMenuItem(
                                const Locale('nl'),
                                '🇳🇱',
                                'Nederlands',
                              ),
                            ],
                          ),
                        ],
                      ),
                      body: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const SizedBox(height: 60),
                                  // Premium logo with glow effect
                                  _buildLogoWithGlow(
                                    context,
                                    company,
                                    themeMode,
                                    colorScheme,
                                  ),
                                  const SizedBox(height: 32),
                                  // Company/App name with gradient
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      company == null
                                          ? widget.title
                                          : company!.name!,
                                      style: TextStyle(
                                        fontSize: isPhone ? 20 : 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  // Premium login button
                                  _buildPremiumButton(
                                    context: context,
                                    key: const Key('loginButton'),
                                    label: _localizations!.login,
                                    isPrimary: true,
                                    colorScheme: colorScheme,
                                    onPressed: () {
                                      _authBloc.add(
                                        AuthUpdateLocal(
                                          state.authenticate!.copyWith(
                                            apiKey: '',
                                          ),
                                        ),
                                      );
                                      showDialog(
                                        barrierDismissible: true,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return BlocProvider.value(
                                            value: _authBloc,
                                            child: const LoginDialog(),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 50),
                                  if (classificationId != 'AppSupport')
                                    _buildPremiumButton(
                                      context: context,
                                      key: const Key('newUserButton'),
                                      label: _localizations!
                                          .registerNewCompanyAndAdmin,
                                      isPrimary: false,
                                      colorScheme: colorScheme,
                                      onPressed: () {
                                        showDialog(
                                          barrierDismissible: true,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return BlocProvider.value(
                                              value: _authBloc,
                                              child: const RegisterUserDialog(
                                                true,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: appInfo,
                  ),
                ],
              ),
            );
          default:
            return Container();
        }
      },
    );

    // Wrap in test banner if in debug/test mode
    if (GlobalConfiguration().get("test") == true &&
        !Platform.isIOS &&
        !Platform.isMacOS) {
      return Banner(
        message: _localizations!.test,
        color: Colors.red,
        location: BannerLocation.topStart,
        child: content,
      );
    }
    return content;
  }

  PopupMenuItem<Locale> _buildLanguageMenuItem(
    Locale locale,
    String flag,
    String name,
  ) {
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Builds logo with premium glow effect
  Widget _buildLogoWithGlow(
    BuildContext context,
    Company? company,
    ThemeMode? themeMode,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.2),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: company != null && company.image != null
            ? ClipOval(
                child: Image.memory(
                  company.image!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              )
            : Image(
                image: AssetImage(
                  themeMode == ThemeMode.light
                      ? 'packages/growerp_core/images/growerp100.png'
                      : 'packages/growerp_core/images/growerpDark100.png',
                ),
                height: 80,
                width: 80,
              ),
      ),
    );
  }

  /// Builds premium styled button with gradient or outline
  Widget _buildPremiumButton({
    required BuildContext context,
    required Key key,
    required String label,
    required bool isPrimary,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          key: key,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      );
    } else {
      return OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}
