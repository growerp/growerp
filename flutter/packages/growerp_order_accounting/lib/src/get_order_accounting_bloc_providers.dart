import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/blocs/invoice_upload/invoice_upload_bloc.dart';

import '../growerp_order_accounting.dart';

List<BlocProvider> getOrderAccountingBlocProviders(
    RestClient restClient, String classificationId) {
  List<BlocProvider> blocProviders = [
    BlocProvider<LedgerBloc>(create: (context) => LedgerBloc(restClient)),
    BlocProvider<GlAccountBloc>(create: (context) => GlAccountBloc(restClient)),
    BlocProvider<InvoiceUploadBloc>(
        create: (context) => InvoiceUploadBloc(restClient)),
    // sales order used in hotel
    BlocProvider<FinDocBloc>(
        create: (context) =>
            FinDocBloc(restClient, true, FinDocType.order, classificationId)),
    BlocProvider<PurchaseOrderBloc>(
        create: (context) =>
            FinDocBloc(restClient, false, FinDocType.order, classificationId)),
    BlocProvider<PurchaseInvoiceBloc>(
        create: (context) => FinDocBloc(
            restClient, false, FinDocType.invoice, classificationId)),
    BlocProvider<PurchasePaymentBloc>(
        create: (context) => FinDocBloc(
            restClient, false, FinDocType.payment, classificationId)),
    BlocProvider<IncomingShipmentBloc>(
        create: (context) => FinDocBloc(
            restClient, false, FinDocType.shipment, classificationId)),
    BlocProvider<SalesOrderBloc>(
        create: (context) =>
            FinDocBloc(restClient, true, FinDocType.order, classificationId)),
    BlocProvider<SalesInvoiceBloc>(
        create: (context) =>
            FinDocBloc(restClient, true, FinDocType.invoice, classificationId)),
    BlocProvider<SalesPaymentBloc>(
        create: (context) =>
            FinDocBloc(restClient, true, FinDocType.payment, classificationId)),
    BlocProvider<OutgoingShipmentBloc>(
        create: (context) => FinDocBloc(
            restClient, true, FinDocType.shipment, classificationId)),
    BlocProvider<TransactionBloc>(
        create: (context) => FinDocBloc(
            restClient, true, FinDocType.transaction, classificationId)),
    BlocProvider<RequestBloc>(
        create: (context) =>
            FinDocBloc(restClient, true, FinDocType.request, classificationId)),
    BlocProvider<LedgerJournalBloc>(
        create: (context) => LedgerJournalBloc(restClient)),
  ];
  return blocProviders;
}
