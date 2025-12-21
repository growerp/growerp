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
import 'package:growerp_models/growerp_models.dart';
import '../../growerp_core.dart';

/// Generic Splash Screen that handles authentication state and menu loading.
///
/// This widget:
/// - Shows login form when not authenticated
/// - Loads menu configuration after authentication
/// - Shows loading indicator while fetching menu
/// - Handles error states with retry option
class AppSplashScreen extends StatefulWidget {
  /// The app title shown in the login form
  final String appTitle;

  /// Empty menu configuration for unauthenticated state
  final MenuConfiguration emptyMenuConfig;

  const AppSplashScreen({
    super.key,
    required this.appTitle,
    required this.emptyMenuConfig,
  });

  /// Convenience factory for creating a splash screen with minimal config
  factory AppSplashScreen.simple({
    Key? key,
    required String appTitle,
    required String appId,
  }) {
    return AppSplashScreen(
      key: key,
      appTitle: appTitle,
      emptyMenuConfig: MenuConfiguration(
        menuItems: [],
        name: 'Login',
        appId: appId,
      ),
    );
  }

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      final menuBloc = context.read<MenuConfigBloc>();
      if (authState.status == AuthStatus.authenticated &&
          menuBloc.state.status == MenuConfigStatus.initial) {
        menuBloc.add(const MenuConfigLoad(userVersion: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.authenticated) {
          final menuBloc = context.read<MenuConfigBloc>();
          if (menuBloc.state.status == MenuConfigStatus.initial) {
            menuBloc.add(const MenuConfigLoad(userVersion: true));
          }
        }
      },
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated) {
          // If not authenticated, show Login Screen (HomeForm)
          return HomeForm(
            menuConfiguration: widget.emptyMenuConfig,
            title: widget.appTitle,
          );
        }

        // Authenticated, waiting for Menu Config
        return Scaffold(
          body: Center(
            child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
              builder: (context, menuState) {
                if (menuState.status == MenuConfigStatus.failure) {
                  return _buildErrorState(context, menuState);
                }

                return _buildLoadingState(context);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, MenuConfigState menuState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'Failed to load menu configuration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          menuState.message ?? 'Unknown error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            context.read<MenuConfigBloc>().add(
              const MenuConfigLoad(userVersion: true),
            );
          },
          child: const Text('Retry'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLoggedOut());
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Loading Menu Configuration...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
