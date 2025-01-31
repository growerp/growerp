// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
      taskId: json['taskId'] as String? ?? "",
      taskType: $enumDecodeNullable(_$TaskTypeEnumMap, json['taskType']) ??
          TaskType.unkwown,
      parentTaskId: json['parentTaskId'] as String? ?? "",
      statusId: $enumDecodeNullable(_$TaskStatusEnumMap, json['statusId']),
      taskName: json['taskName'] as String? ?? "",
      description: json['description'] as String? ?? "",
      customerUser: json['customerUser'] == null
          ? null
          : User.fromJson(json['customerUser'] as Map<String, dynamic>),
      vendorUser: json['vendorUser'] == null
          ? null
          : User.fromJson(json['vendorUser'] as Map<String, dynamic>),
      employeeUser: json['employeeUser'] == null
          ? null
          : User.fromJson(json['employeeUser'] as Map<String, dynamic>),
      rate: json['rate'] == null
          ? null
          : Decimal.fromJson(json['rate'] as String),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      unInvoicedHours: json['unInvoicedHours'] == null
          ? null
          : Decimal.fromJson(json['unInvoicedHours'] as String),
      timeEntries: (json['timeEntries'] as List<dynamic>?)
              ?.map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      jsonImage: json['jsonImage'] as String? ?? "",
      workflowTasks: (json['workflowTasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      taskTemplate: json['taskTemplate'] == null
          ? null
          : Task.fromJson(json['taskTemplate'] as Map<String, dynamic>),
      routing: json['routing'] as String?,
      flowElementId: json['flowElementId'] as String?,
    );

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'taskType': _$TaskTypeEnumMap[instance.taskType]!,
      'parentTaskId': instance.parentTaskId,
      'statusId': _$TaskStatusEnumMap[instance.statusId],
      'taskName': instance.taskName,
      'description': instance.description,
      'customerUser': instance.customerUser,
      'vendorUser': instance.vendorUser,
      'employeeUser': instance.employeeUser,
      'rate': instance.rate,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'unInvoicedHours': instance.unInvoicedHours,
      'timeEntries': instance.timeEntries,
      'jsonImage': instance.jsonImage,
      'workflowTasks': instance.workflowTasks,
      'taskTemplate': instance.taskTemplate,
      'routing': instance.routing,
      'flowElementId': instance.flowElementId,
    };

const _$TaskTypeEnumMap = {
  TaskType.todo: 'todo',
  TaskType.workflow: 'workflow',
  TaskType.workflowTask: 'workflowTask',
  TaskType.workflowTemplate: 'workflowTemplate',
  TaskType.workflowTemplateTask: 'workflowTemplateTask',
  TaskType.workflowTaskTemplate: 'workflowTaskTemplate',
  TaskType.unkwown: 'unkwown',
};

const _$TaskStatusEnumMap = {
  TaskStatus.planning: 'planning',
  TaskStatus.progress: 'progress',
  TaskStatus.completed: 'completed',
  TaskStatus.onHold: 'onHold',
  TaskStatus.closed: 'closed',
  TaskStatus.unkwown: 'unkwown',
};
