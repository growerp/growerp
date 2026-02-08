import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:go_router/go_router.dart';

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
    //    if (finDoc.docType == FinDocType.order &&
    //        (finDoc.status == FinDocStatusVal.inPreparation ||
    //            finDoc.status == FinDocStatusVal.created)) return Container();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Wrap(
        spacing: 5,
        children: [
          // Hidden text widgets for test access to related IDs
          if (finDoc.orderId != null)
            Text(
              finDoc.orderId!,
              key: const Key('relOrderId'),
              style: const TextStyle(fontSize: 0),
            ),
          if (finDoc.invoiceId != null)
            Text(
              finDoc.invoiceId!,
              key: const Key('relInvoiceId'),
              style: const TextStyle(fontSize: 0),
            ),
          if (finDoc.paymentId != null)
            Text(
              finDoc.paymentId!,
              key: const Key('relPaymentId'),
              style: const TextStyle(fontSize: 0),
            ),
          if (finDoc.shipmentId != null)
            Text(
              finDoc.shipmentId!,
              key: const Key('relShipmentId'),
              style: const TextStyle(fontSize: 0),
            ),
          if (finDoc.transactionId != null)
            Text(
              finDoc.transactionId!,
              key: const Key('relTransactionId'),
              style: const TextStyle(fontSize: 0),
            ),
          if (finDoc.docType != FinDocType.order && finDoc.orderId != null)
            OutlinedButton(
              key: const Key('relOrder'),
              child: const Text('Order'),
              onPressed: () => context.push(
                '/findoc',
                extra: FinDoc(
                  sales: finDoc.sales,
                  docType: FinDocType.order,
                  orderId: finDoc.orderId,
                ),
              ),
            ),
          if (finDoc.docType != FinDocType.invoice && finDoc.invoiceId != null)
            OutlinedButton(
              key: const Key('relInvoice'),
              child: const Text('Invoice'),
              onPressed: () => context.push(
                '/findoc',
                extra: FinDoc(
                  sales: finDoc.sales,
                  docType: FinDocType.invoice,
                  invoiceId: finDoc.invoiceId,
                ),
              ),
            ),
          if (finDoc.docType != FinDocType.payment && finDoc.paymentId != null)
            OutlinedButton(
              key: const Key('relPayment'),
              child: const Text('Payment'),
              onPressed: () => context.push(
                '/findoc',
                extra: FinDoc(
                  sales: finDoc.sales,
                  docType: FinDocType.payment,
                  paymentId: finDoc.paymentId,
                ),
              ),
            ),
          if (finDoc.docType != FinDocType.shipment &&
              finDoc.shipmentId != null)
            OutlinedButton(
              key: const Key('relShipment'),
              child: const Text('Shipment'),
              onPressed: () => context.push(
                '/findoc',
                extra: FinDoc(
                  sales: finDoc.sales,
                  docType: FinDocType.shipment,
                  shipmentId: finDoc.shipmentId,
                ),
              ),
            ),
          if (finDoc.docType != FinDocType.transaction &&
              finDoc.transactionId != null)
            OutlinedButton(
              key: const Key('relTransaction'),
              child: const Text('Transaction'),
              onPressed: () => context.push(
                '/findoc',
                extra: FinDoc(
                  sales: finDoc.sales,
                  docType: FinDocType.transaction,
                  transactionId: finDoc.transactionId,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
