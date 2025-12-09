import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Dashboard for core example - displays dashboard panels from menu configuration
class CoreDashboard extends StatelessWidget {
  const CoreDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            // Use menu configuration from bloc if available
            final menuConfig = menuState.menuConfiguration;

            if (menuConfig == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get dashboard items from menu configuration (top-level, active items only)
            // Exclude the Main/Dashboard item itself (route '/')
            final dashboardItems =
                menuConfig.menuOptions
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != '/' &&
                          option.route != '/about',
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isAPhone(context) ? 200 : 300,
                  childAspectRatio: 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: dashboardItems.length,
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return DashboardCard(
                    title: item.title,
                    iconName: item.iconName ?? 'dashboard',
                    route: item.route,
                    stats: getStatsForRoute(item.route, stats),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AuthenticatedDisplayMenuOption extends StatelessWidget {
  const AuthenticatedDisplayMenuOption({
    super.key,
    required this.menuConfiguration,
    required this.menuIndex,
    required this.child,
  });

  final MenuConfiguration menuConfiguration;
  final int menuIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Hidden API key widgets are now handled by DisplayMenuOption's _buildHiddenTestWidgets()
    return DisplayMenuOption(
      menuConfiguration: menuConfiguration,
      menuIndex: menuIndex,
      actions: [
        IconButton(
          key: const Key('logoutButton'),
          icon: const Icon(Icons.do_not_disturb, key: Key('HomeFormAuth')),
          onPressed: () => context.read<AuthBloc>().add(const AuthLoggedOut()),
        ),
      ],
      child: child,
    );
  }
}
