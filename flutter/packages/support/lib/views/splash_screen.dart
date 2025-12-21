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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      final menuBloc = context.read<MenuConfigBloc>();
      if (authState.status == AuthStatus.authenticated &&
          menuBloc.state.status == MenuConfigStatus.initial) {
        menuBloc.add(const MenuConfigLoad());
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
            menuBloc.add(const MenuConfigLoad());
          }
        }
      },
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated) {
          // If not authenticated, show Login Screen (HomeForm)
          // We pass an empty configuration as it's not needed for login
          return HomeForm(
            menuConfiguration: const MenuConfiguration(
              menuItems: [],
              name: 'Login',
              appId: 'support',
            ),
            title: 'GrowERP Support',
          );
        }

        // Authenticated, waiting for Menu Config
        return Scaffold(
          body: Center(
            child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
              builder: (context, menuState) {
                if (menuState.status == MenuConfigStatus.failure) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
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
                            const MenuConfigLoad(),
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
              },
            ),
          ),
        );
      },
    );
  }
}
