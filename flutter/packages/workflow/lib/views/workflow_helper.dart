import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class WorkflowHelper {
  static saveWorkflow(
    BuildContext context,
    Task workflow,
    Dashboard dashboard,
  ) {
    Task newWorkflow = Task(
        taskId: workflow.taskId,
        statusId: workflow.statusId,
        taskName: workflow.taskName,
        description: workflow.description);
    List<Task> newWorkflowTasks = [];
    for (var element in dashboard.elements) {
      if (element == dashboard.elements.first) {
        newWorkflow = newWorkflow.copyWith(
            flowElementId: element.id, jsonImage: dashboard.toJson());
      } else {
        newWorkflowTasks.add(Task(
            taskType: TaskType.workflowTemplateTask,
            flowElementId: element.id,
            routing: '??'));
      }
    }
    context
        .read<TaskBloc>()
        .add(TaskUpdate(newWorkflow.copyWith(workflowTasks: newWorkflowTasks)));
  }
}
