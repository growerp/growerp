import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
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
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.order,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<PurchaseOrderBloc>(
      create: (context) => FinDocBloc(
        restClient,
        false,
        FinDocType.order,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<PurchaseInvoiceBloc>(
      create: (context) => FinDocBloc(
        restClient,
        false,
        FinDocType.invoice,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<PurchasePaymentBloc>(
      create: (context) => FinDocBloc(
        restClient,
        false,
        FinDocType.payment,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<IncomingShipmentBloc>(
      create: (context) => FinDocBloc(
        restClient,
        false,
        FinDocType.shipment,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<SalesOrderBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.order,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<SalesInvoiceBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.invoice,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<SalesPaymentBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.payment,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<OutgoingShipmentBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.shipment,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<TransactionBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.transaction,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<RequestBloc>(
      create: (context) => FinDocBloc(
        restClient,
        true,
        FinDocType.request,
        applicationId,
        authBloc: context.read<AuthBloc>(),
      ),
    ),
    BlocProvider<LedgerJournalBloc>(
      create: (context) => LedgerJournalBloc(restClient),
    ),
  ];
  return blocProviders;
}
