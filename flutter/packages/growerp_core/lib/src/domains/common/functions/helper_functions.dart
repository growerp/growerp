/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:universal_io/io.dart';
import 'package:http/http.dart' show get;
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../domains.dart';

class HelperFunctions {
  static void showMessage(
    BuildContext context,
    String? message,
    Color color, {
    int? seconds,
  }) {
    if (message != null && message != "null") {
      try {
        final messenger =
            ScaffoldMessenger.maybeOf(context) ??
            Constant.scaffoldMessengerKey.currentState;
        if (messenger == null) {
          debugPrint('SnackBar not shown - no Scaffold available: $message');
          return;
        }
        // Use try-catch for hideCurrentSnackBar in case scaffold is disposed
        try {
          messenger.hideCurrentSnackBar();
        } catch (e) {
          debugPrint('Could not hide snackbar: $e');
        }

        final controller = messenger.showSnackBar(
          snackBar(context, color, message, seconds: seconds),
        );

        var isClosed = false;
        controller.closed.whenComplete(() => isClosed = true);
        final duration = snackBarDuration(color, seconds: seconds);
        // Ensure snackbars still disappear when accessibility keeps them alive.
        Future.delayed(duration, () {
          if (!isClosed) {
            try {
              controller.close();
            } catch (e) {
              // Scaffold may have been disposed, ignore
              debugPrint('Could not close snackbar: $e');
            }
          }
        });
      } catch (e) {
        // ScaffoldMessenger not available yet, ignore silently
        debugPrint('SnackBar not shown - no Scaffold available: $message');
      }
    }
  }

  static void showTopMessage(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    try {
      final messenger =
          ScaffoldMessenger.maybeOf(context) ??
          Constant.scaffoldMessengerKey.currentState;
      if (messenger == null) {
        debugPrint('TopMessage not shown - no Scaffold available: $message');
        return;
      }
      final colorScheme = Theme.of(context).colorScheme;
      messenger.showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.up,
          duration: duration ?? const Duration(milliseconds: 3000),
          backgroundColor: colorScheme.primary,
          margin: EdgeInsets.only(
            top: 100,
            bottom: MediaQuery.of(context).size.height - 200,
            left: 20,
            right: 20,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.onPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // ScaffoldMessenger not available yet, ignore silently
      debugPrint('TopMessage not shown - no Scaffold available: $message');
    }
  }

  static Future<Uint8List?> getResizedImage(String? imagePath) async {
    if (imagePath != null) {
      const LoadingIndicator();
      Uint8List imageData;
      if (kIsWeb) {
        var response = await get(Uri.parse(imagePath));
        imageData = response.bodyBytes;
      } else {
        imageData = File(imagePath).readAsBytesSync();
      }
      if (imageData.length > 200000) {
        image.Image img = image.decodeImage(imageData)!;
        image.Image resized = image.copyResize(img, width: -1, height: 200);
        imageData = image.encodeJpg(resized);
      }
      return imageData;
    } else {
      return null;
    }
  }

  static Future<XFile?> pickImage() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return await ImagePicker().pickImage(source: ImageSource.gallery);
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        return XFile(result.files.single.path!);
      }
    }
    return null;
  }

  static String translateMenuTitle(
    CoreLocalizations localizations,
    String key,
  ) {
    switch (key) {
      case 'customers':
        return localizations.customers;
      case 'suppliers':
        return localizations.suppliers;
      case 'salesOrders':
        return localizations.salesOrders;
      case 'purchaseOrders':
        return localizations.purchaseOrders;
      case 'employees':
        return localizations.employees;
      case 'leads':
        return localizations.leads;
      case 'reservations':
        return localizations.reservations;
      case 'subscriptions':
        return localizations.subscriptions;
      case 'setUp':
        return localizations.setUp;
      case 'transactions':
        return localizations.transactions;
      case 'ledgerTransaction':
        return localizations.ledgerTransaction;
      case 'incomingPayments':
        return localizations.incomingPayments;
      case 'outgoingPayments':
        return localizations.outgoingPayments;
      case 'company':
        return localizations.company;
      case 'about':
        return localizations.about;
      case 'main':
        return localizations.main;
      case 'organization':
        return localizations.organization;
      case 'reports':
        return localizations.reports;
      case 'crm':
        return localizations.crm;
      case 'catalog':
        return localizations.catalog;
      case 'orders':
        return localizations.orders;
      case 'inventory':
        return localizations.inventory;
      case 'accounting':
        return localizations.accounting;
      default:
        return key;
    }
  }
}
