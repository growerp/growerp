import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'findoc/views/views.dart';

class FinDocServices {
  void OrderEntry(FinDoc) {
    ShowFinDocDialog(FinDoc());
  }

  void ReceiveShipment(FinDoc) {
    ShipmentReceiveDialog(FinDoc());
  }
}

Map<String, Widget> orderAccountingScreens = {
  'salesOrderEntry':
      ShowFinDocDialog(FinDoc(docType: FinDocType.order, sales: true)),
  'purchaseOrderEntry':
      ShowFinDocDialog(FinDoc(docType: FinDocType.order, sales: false)),
};
