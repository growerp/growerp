class FlowData {
  String taskId;
  String name;
  String routing;

  FlowData({
    this.taskId = '',
    this.name = '',
    this.routing = '',
  });

  FlowData copyWith({
    String? taskId,
    String? name,
    String? routing,
  }) {
    return FlowData(
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      routing: routing ?? this.routing,
    );
  }

  @override
  String toString() {
    return ("Data id: $taskId name: $name routing: $routing");
  }
}
