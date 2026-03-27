import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Dashboard for courses example - displays dashboard panels from menu configuration
class CoursesDashboard extends StatelessWidget {
  const CoursesDashboard({super.key, required this.menuConfiguration});

  final MenuConfiguration menuConfiguration;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        final dashboardItems = menuConfiguration.menuItems
            .where(
              (option) =>
                  option.isActive &&
                  option.route != '/' &&
                  option.route != '/about',
            )
            .toList()
          ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

        return DashboardGrid(items: dashboardItems, stats: stats);
      },
    );
  }
}
