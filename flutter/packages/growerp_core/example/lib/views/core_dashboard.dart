import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Dashboard for core example - displays dashboard panels from menu configuration
class CoreDashboard extends StatelessWidget {
  const CoreDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuConfigBloc, MenuConfigState>(
      builder: (context, state) {
        // Use menu configuration from bloc if available
        final menuConfig = state.menuConfiguration;

        if (menuConfig == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get dashboard items from menu configuration (top-level, active items only)
        // Exclude the Main/Dashboard item itself (route '/')
        final dashboardItems =
            menuConfig.menuItems
                .where(
                  (item) =>
                      item.isActive &&
                      item.parentOptionItemId == null &&
                      item.route != '/' &&
                      item.route != '/about',
                )
                .toList()
              ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            key: const Key('coreFab'),
            tooltip: 'Manage Menu Items',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => BlocProvider.value(
                  value: context.read<MenuConfigBloc>(),
                  child: MenuItemListDialog(menuConfiguration: menuConfig),
                ),
              );
            },
            child: const Icon(Icons.menu),
          ),
          body: Padding(
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
                return _DashboardCard(
                  title: item.title,
                  iconName: item.iconName ?? 'dashboard',
                  route: item.route,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String iconName;
  final String? route;
  final String? stats;

  const _DashboardCard({
    required this.title,
    required this.iconName,
    this.route,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: route != null ? () => context.go(route!) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              getIconFromRegistry(iconName) ??
                  const Icon(Icons.dashboard, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stats != null) ...[
                const SizedBox(height: 8),
                Text(
                  stats!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: DisplayMenuOption(
                menuConfiguration: menuConfiguration,
                menuIndex: menuIndex,
                actions: [
                  IconButton(
                    key: const Key('logoutButton'),
                    icon: const Icon(
                      Icons.do_not_disturb,
                      key: Key('HomeFormAuth'),
                    ),
                    onPressed: () =>
                        context.read<AuthBloc>().add(const AuthLoggedOut()),
                  ),
                ],
                child: child,
              ),
            ),
            if (!kReleaseMode && state.authenticate?.apiKey != null) ...[
              Text(
                state.authenticate!.apiKey!,
                key: const Key('apiKey'),
                style: const TextStyle(fontSize: 0),
              ),
              if (state.authenticate?.moquiSessionToken != null)
                Text(
                  state.authenticate!.moquiSessionToken!,
                  key: const Key('moquiSessionToken'),
                  style: const TextStyle(fontSize: 0),
                ),
            ],
          ],
        );
      },
    );
  }
}
