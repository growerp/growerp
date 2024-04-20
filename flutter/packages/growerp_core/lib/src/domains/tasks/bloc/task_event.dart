/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object> get props => [];
}

class TaskFetch extends TaskEvent {
  const TaskFetch({
    this.limit = 20,
    this.my = true,
    this.searchString = '',
    this.refresh = false,
    this.isForDropDown = false,
    this.taskId = '',
  });
  final bool my;
  final String searchString;
  final bool refresh;
  final int limit;
  final bool isForDropDown;
  final String taskId;
  @override
  List<Object> get props => [searchString, refresh, taskId, isForDropDown];
}

class TaskUpdate extends TaskEvent {
  const TaskUpdate(this.task);
  final Task task;
}

class TaskTimeEntryUpdate extends TaskEvent {
  const TaskTimeEntryUpdate(this.timeEntry);
  final TimeEntry timeEntry;
}

class TaskTimeEntryDelete extends TaskEvent {
  const TaskTimeEntryDelete(this.timeEntry);
  final TimeEntry timeEntry;
}

class TaskWorkflowNext extends TaskEvent {
  const TaskWorkflowNext(this.workflowId);
  final String workflowId;
}

class TaskWorkflowPrevious extends TaskEvent {
  const TaskWorkflowPrevious(this.workflowId);
  final String workflowId;
}

class TaskWorkflowCancel extends TaskEvent {
  const TaskWorkflowCancel(this.workflowId);
  final String workflowId;
}

class TaskWorkflowSuspend extends TaskEvent {
  const TaskWorkflowSuspend(this.workflowId);
  final String workflowId;
}

class TaskSetReturnString extends TaskEvent {
  const TaskSetReturnString(this.returnString);
  final String returnString;
}

class TaskGetUserWorkflows extends TaskEvent {
  const TaskGetUserWorkflows(this.taskType);
  final TaskType taskType;
}

class TaskCreateUserWorkflow extends TaskEvent {
  const TaskCreateUserWorkflow(this.workflowId);
  final String workflowId;
}

class TaskDeleteUserWorkflow extends TaskEvent {
  const TaskDeleteUserWorkflow(this.workflowId);
  final String workflowId;
}
