import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

class RelatedFinDocs extends StatelessWidget {
  const RelatedFinDocs({
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
        child: Wrap(spacing: 5, children: [
          if (finDoc.docType != FinDocType.order && finDoc.orderId != null)
            OutlinedButton(
                key: const Key('relOrder'),
                child: const Text('Order'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.order,
                        orderId: finDoc.orderId))),
          if (finDoc.docType != FinDocType.invoice && finDoc.invoiceId != null)
            OutlinedButton(
                key: const Key('relInvoice'),
                child: const Text('Invoice'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.invoice,
                        invoiceId: finDoc.invoiceId))),
          if (finDoc.docType != FinDocType.payment && finDoc.paymentId != null)
            OutlinedButton(
                key: const Key('relPayment'),
                child: const Text('Payment'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.payment,
                        paymentId: finDoc.paymentId))),
          if (finDoc.docType != FinDocType.shipment &&
              finDoc.shipmentId != null)
            OutlinedButton(
                key: const Key('relShipment'),
                child: const Text('Shipment'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.shipment,
                        shipmentId: finDoc.shipmentId))),
          if (finDoc.docType != FinDocType.transaction &&
              finDoc.transactionId != null)
            OutlinedButton(
                key: const Key('relTransaction'),
                child: const Text('Transaction'),
                onPressed: () => Navigator.pushNamed(context, '/findoc',
                    arguments: FinDoc(
                        sales: finDoc.sales,
                        docType: FinDocType.transaction,
                        transactionId: finDoc.transactionId))),
        ]));
  }
}
