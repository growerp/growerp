import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

List<MenuOption> workflowMenuOptions = [
  MenuOption(
    title: "Workflow running here",
    route: '/',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const Text("dummy"),
  ),
  MenuOption(
    title: "Related Workflow diagram",
    route: '/showDiagram',
    readGroups: [UserGroup.admin, UserGroup.employee],
    writeGroups: [UserGroup.admin],
    child: const Text(''), // will be updated by the bloc with paramaters
  ),
];
