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
import '../l10n/generated/support_localizations.dart';
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
          // We pass an empty configuration as it's not needed for login
          return HomeForm(
            menuConfiguration: MenuConfiguration(
              menuItems: [],
              name: SupportLocalizations.of(context)!.login,
              appId: 'support',
            ),
            title: SupportLocalizations.of(context)!.growerpSupport,
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
                        SupportLocalizations.of(context)!.failedToLoadMenuConfiguration,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        menuState.message ?? SupportLocalizations.of(context)!.unknownError,
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
                        child: Text(SupportLocalizations.of(context)!.retry),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(const AuthLoggedOut());
                        },
                        child: Text(SupportLocalizations.of(context)!.logout),
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
                      SupportLocalizations.of(context)!.loadingMenuConfiguration,
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
