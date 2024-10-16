import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'findoc/views/views.dart';

/*
class FinDocServices {
  void orderEntry(FinDoc) {
    FinDocDialog(FinDoc());
  }

  void receiveShipment(FinDoc) {
    ShipmentReceiveDialog(FinDoc());
  }
}
*/
Map<String, Widget> orderAccountingScreens = {
  'salesorderEntry':
      FinDocDialog(FinDoc(docType: FinDocType.order, sales: true)),
  'purchaseorderEntry':
      FinDocDialog(FinDoc(docType: FinDocType.order, sales: false)),
};
