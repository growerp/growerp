# GrowERP Flutter ERP Workflow App.

This is the workflow app, being able to create cust workflows using the growERP system.

under development


entities:


Workflow
	workflowId/date
	name,
	description,
	image (json)

WorkflowElements
	workflowId/date
    elementId
	
workflowElementLinks
	workflowId/date
	fromElementId
	toElementId
	condition
	
workflow elements
	WorkflowElementId
	name
    description
	uiScreen
	
workflowActive
	user,
	workflowId/date,
	current element
	data
	element history
	
packages to be used:
[flutter flowbuilder package](https://pub.dev/packages/flow_builder)
[workflow editor](https://github.com/alnitak/flutter_flow_chart)

