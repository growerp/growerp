# GrowERP Flutter ERP Workflow App.

This is the workflow app, being able to create cust workflows using the growERP system.

under development


entities:

Workflow
	workflowId
	name,
	description,
	image (json)

WorkflowTasks
	workflowId
    taskId
	
workflowTaskLinks
	workflowId
	fromTaskId
	toTaskId
    condition
	
Tasks
	TaskId
	name
    description
	uiScreen

	
WorkflowsActive
	workflowId
    startdate,
    statusId
	current task
	data(json)
	task history
	
packages to be used:
[flutter flowbuilder package](https://pub.dev/packages/flow_builder)
[workflow editor](https://github.com/alnitak/flutter_flow_chart)

screens:

1. workflow list
2. detail workflow to flowchart editor
3. task list
4. task detail popup
5. Active workflow list

