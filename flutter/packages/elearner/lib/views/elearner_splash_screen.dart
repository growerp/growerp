/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Splash screen that loads the appropriate menu config based on the user's role:
/// - admin / employee  → appId 'elearner_admin'
/// - customer (other)  → appId 'elearner'
class ElearnerSplashScreen extends StatefulWidget {
  const ElearnerSplashScreen({super.key});

  @override
  State<ElearnerSplashScreen> createState() => _ElearnerSplashScreenState();
}

class _ElearnerSplashScreenState extends State<ElearnerSplashScreen> {
  static const _emptyCustomerMenu = MenuConfiguration(
    menuItems: [],
    name: 'Login',
    appId: 'elearner',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated) {
        context
            .read<MenuConfigBloc>()
            .add(MenuConfigLoad(appId: _appIdFor(authState), userVersion: true));
      }
    });
  }

  String _appIdFor(AuthState authState) {
    final group = authState.authenticate?.user?.userGroup;
    if (group == UserGroup.admin || group == UserGroup.employee) {
      return 'elearner_admin';
    }
    return 'elearner';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.authenticated) {
          context
              .read<MenuConfigBloc>()
              .add(MenuConfigLoad(appId: _appIdFor(authState), userVersion: true));
        }
      },
      builder: (context, authState) {
        if (authState.status != AuthStatus.authenticated) {
          return HomeForm(
            menuConfiguration: _emptyCustomerMenu,
            title: 'GrowERP eLearner',
          );
        }

        return Scaffold(
          body: Center(
            child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
              builder: (context, menuState) {
                if (menuState.status == MenuConfigStatus.failure) {
                  return _buildErrorState(context, menuState, authState);
                }
                return _buildLoadingState(context);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    MenuConfigState menuState,
    AuthState authState,
  ) {
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
          onPressed: () => context
              .read<MenuConfigBloc>()
              .add(MenuConfigLoad(appId: _appIdFor(authState), userVersion: true)),
          child: const Text('Retry'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLoggedOut()),
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
          'Loading...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
