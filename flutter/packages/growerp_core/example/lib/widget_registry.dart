import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'views/core_dashboard.dart';

/// Widget registry for Core Example app
/// Maps backend widget names to Flutter widgets
class WidgetRegistry {
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    switch (widgetName) {
      // Dashboard
      case 'CoreDashboard':
        return const CoreDashboard();

      // About page
      case 'AboutForm':
        return const AboutForm();

      // Company widgets (from growerp_user_company)
      case 'ShowCompanyDialog':
        // Display company information as a full page (not a dialog)
        return ShowCompanyDialog(Company(), dialog: false);

      // User widgets (from growerp_user_company)
      case 'UserList':
        // User list with optional role filter
        return UserList(key: _getKey(args), role: _parseRole(args?['role']));

      default:
        return Center(child: Text("Widget $widgetName not found"));
    }
  }

  static Key? _getKey(Map<String, dynamic>? args) {
    if (args != null && args.containsKey('key')) {
      return Key(args['key']);
    }
    return null;
  }

  static Role _parseRole(String? roleName) {
    if (roleName == null) return Role.unknown;
    try {
      return Role.values.firstWhere(
        (e) => e.name.toLowerCase() == roleName.toLowerCase(),
        orElse: () => Role.unknown,
      );
    } catch (_) {
      return Role.unknown;
    }
  }
}
