import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/src/findoc/blocs/invoice_upload/invoice_upload_bloc.dart';

import '../growerp_order_accounting.dart';

List<BlocProvider> getOrderAccountingBlocProviders(
  RestClient restClient,
  String applicationId,
) {
  List<BlocProvider> blocProviders = [
    BlocProvider<LedgerBloc>(create: (context) => LedgerBloc(restClient)),
    BlocProvider<GlAccountBloc>(create: (context) => GlAccountBloc(restClient)),
    BlocProvider<InvoiceUploadBloc>(
      create: (context) => InvoiceUploadBloc(restClient),
    ),
    // sales order used in hotel
    BlocProvider<FinDocBloc>(
      create: (context) =>
          FinDocBloc(restClient, true, FinDocType.order, applicationId),
    ),
    BlocProvider<PurchaseOrderBloc>(
      create: (context) =>
          FinDocBloc(restClient, false, FinDocType.order, applicationId),
    ),
    BlocProvider<PurchaseInvoiceBloc>(
      create: (context) =>
          FinDocBloc(restClient, false, FinDocType.invoice, applicationId),
    ),
    BlocProvider<PurchasePaymentBloc>(
      create: (context) =>
          FinDocBloc(restClient, false, FinDocType.payment, applicationId),
    ),
    BlocProvider<IncomingShipmentBloc>(
      create: (context) =>
          FinDocBloc(restClient, false, FinDocType.shipment, applicationId),
    ),
    BlocProvider<SalesOrderBloc>(
      create: (context) =>
          FinDocBloc(restClient, true, FinDocType.order, applicationId),
    ),
    BlocProvider<SalesInvoiceBloc>(
      create: (context) =>
          FinDocBloc(restClient, true, FinDocType.invoice, applicationId),
    ),
    BlocProvider<SalesPaymentBloc>(
      create: (context) =>
          FinDocBloc(restClient, true, FinDocType.payment, applicationId),
    ),
    BlocProvider<OutgoingShipmentBloc>(
      create: (context) =>
          FinDocBloc(restClient, true, FinDocType.shipment, applicationId),
    ),
    BlocProvider<TransactionBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.transaction,
        applicationId,
      ),
    ),
    BlocProvider<RequestBloc>(
      create: (context) =>
          FinDocBloc(restClient, true, FinDocType.request, applicationId),
    ),
    BlocProvider<LedgerJournalBloc>(
      create: (context) => LedgerJournalBloc(restClient),
    ),
  ];
  return blocProviders;
}
