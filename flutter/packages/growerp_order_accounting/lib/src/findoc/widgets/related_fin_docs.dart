import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

class relatedFinDocs extends StatelessWidget {
  const relatedFinDocs({
    super.key,
    required this.finDoc,
    required this.context,
  });

  final FinDoc finDoc;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    if (finDoc.id() == null) return Container();
    if (finDoc.docType == FinDocType.order &&
        (finDoc.status == FinDocStatusVal.inPreparation ||
            finDoc.status == FinDocStatusVal.created)) return Container();
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (finDoc.docType != FinDocType.order && finDoc.orderId != null)
            TextButton(
                key: Key('relOrder'),
                child: Text('Order'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.order,
                        orderId: finDoc.orderId))),
          if (finDoc.docType != FinDocType.invoice && finDoc.invoiceId != null)
            TextButton(
                key: Key('relInvoice'),
                child: Text('Invoice'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.invoice,
                        invoiceId: finDoc.invoiceId))),
          if (finDoc.docType != FinDocType.payment && finDoc.paymentId != null)
            TextButton(
                key: Key('relPayment'),
                child: Text('Payment'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.payment,
                        paymentId: finDoc.paymentId))),
          if (finDoc.docType != FinDocType.shipment &&
              finDoc.shipmentId != null)
            TextButton(
                key: Key('relShipment'),
                child: Text('Shipment'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.shipment,
                        shipmentId: finDoc.shipmentId))),
          if (finDoc.docType != FinDocType.transaction &&
              finDoc.transactionId != null)
            TextButton(
                key: Key('relTransaction'),
                child: Text('Transaction'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.transaction,
                        transactionId: finDoc.transactionId))),
        ]));
  }
}
