import 'package:growerp_models/growerp_models.dart';

class FlowData {
  Task? workflowTaskTemplate;
  String flowElementId;
  String name;
  String routing;

  FlowData({
    this.workflowTaskTemplate,
    this.name = '',
    this.routing = '',
    this.flowElementId = '',
  });

  FlowData copyWith({
    Task? workflowTaskTemplate,
    String? flowElementId,
    String? name,
    String? routing,
  }) {
    return FlowData(
      workflowTaskTemplate: workflowTaskTemplate ?? this.workflowTaskTemplate,
      name: name ?? this.name,
      flowElementId: flowElementId ?? this.flowElementId,
      routing: routing ?? this.routing,
    );
  }

  @override
  String toString() {
    return ("Data taskId: ${workflowTaskTemplate?.taskId} name: $name routing: $routing");
  }
}
