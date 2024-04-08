import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_task/growerp_task.dart';

class TaskServices {
  Widget editTask(Task task) {
    return TaskDialog(task);
  }
}

Map<String, Widget> taskScreens = {
  'editTask': TaskDialog(Task()),
};
