import 'package:flutter/material.dart';
import 'package:growerp_order_accounting/src/findoc/views/invoice_upload_view.dart';

Route<dynamic>? orderAccountingRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/findoc/upload':
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => const InvoiceUploadView());
    default:
      return null;
  }
}