/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
          // Always reload on auth transition so a newly logged-in user/company
          // gets their own fresh menu config, not the previous user's state.
          context
              .read<MenuConfigBloc>()
              .add(const MenuConfigLoad(userVersion: true));
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
        SizedBox(height: 16),
        Text(
          CoreLocalizations.of(context)!.failedToLoadMenuConfiguration,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          menuState.message ?? 'Unknown error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            context.read<MenuConfigBloc>().add(
              const MenuConfigLoad(userVersion: true),
            );
          },
          child: Text(CoreLocalizations.of(context)!.retry),
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLoggedOut());
          },
          child: Text(CoreLocalizations.of(context)!.logout),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        SizedBox(height: 24),
        Text(
          'Loading Menu Configuration...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
