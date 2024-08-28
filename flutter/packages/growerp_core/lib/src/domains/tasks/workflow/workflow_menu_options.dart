import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> workflowMenuOptions = [
  MenuOption(
    title: "Workflow running here",
    route: '/',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const Text("dummy"),
  ),
  MenuOption(
    title: "Related Workflow diagram",
    route: '/showDiagram',
    userGroups: [UserGroup.admin, UserGroup.employee],
    child: const Text(''), // will be updated by the bloc with paramaters
  ),
];
