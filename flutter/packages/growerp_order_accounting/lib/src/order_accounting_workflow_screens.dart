import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'findoc/views/views.dart';

Map<String, Widget> orderAccountingWorkflowScreens = {
  "orderEntry":
      ShowFinDocDialog(FinDoc(sales: true, docType: FinDocType.order)),
  "receiveShipment": ShipmentReceiveDialog(FinDoc()),
};
