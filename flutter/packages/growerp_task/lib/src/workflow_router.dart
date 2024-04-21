import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

Route workflowGenerateRoute(RouteSettings settings) {
  debugPrint('>>>Workflow NavigateTo { ${settings.name} '
      'with: ${settings.arguments.toString()} }');

  late Widget page;
  switch (settings.name) {
    case '/':
      page = DisplayMenuOption(
          menuList: (settings.arguments as Map)['menuList'] as List<MenuOption>,
          menuIndex: 0,
          workflow: (settings.arguments as Map)['workflow'] as Task);
      break;
    case '/showDiagram':
      page = DisplayMenuOption(
          menuList: settings.arguments as List<MenuOption>, menuIndex: 1);
      break;
  }

  return MaterialPageRoute<dynamic>(
    builder: (context) {
      return page;
    },
    settings: settings,
  );
}
