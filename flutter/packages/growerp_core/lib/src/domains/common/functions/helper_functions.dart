/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:universal_io/io.dart';
import 'package:http/http.dart' show get;
import 'package:growerp_core/l10n/generated/core_localizations.dart';
import 'package:growerp_core/src/common/translate_bloc_messages.dart';
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
      // BLoCs emit message keys, so translate before display. Every caller has a
      // context below MaterialApp; free text and unknown keys pass through.
      final localizations = CoreLocalizations.of(context);
      if (localizations != null) {
        message = translateAuthBlocMessage(message, localizations);
      }
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
          if (!isClosed && messenger.mounted) {
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

  /// Translate a backend [MenuItem.title] into the current app language.
  ///
  /// Titles are seed data (GrowerpMenuSeedData.xml and friends) and are not
  /// consistently keyed: some are camelCase pseudo keys ('salesOrders'), some
  /// are English phrases ('Acct Sales'), and get#MenuConfiguration capitalizes
  /// the first letter of every one of them. So match on the title stripped of
  /// case and everything that is not a letter or digit; a title without a
  /// translation falls through unchanged.
  static String translateMenuTitle(
    CoreLocalizations localizations,
    String title,
  ) {
    final key = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    switch (key) {
      case 'about':
        return localizations.about;
      case 'accounting':
        return localizations.accounting;
      case 'acctledger':
        return localizations.acctLedger;
      case 'acctpurchase':
        return localizations.acctPurchase;
      case 'acctreports':
        return localizations.acctReports;
      case 'acctsales':
        return localizations.acctSales;
      case 'acctsetup':
        return localizations.acctSetup;
      case 'agentactions':
        return localizations.agentActions;
      case 'agentcontrol':
        return localizations.agentControl;
      case 'agentjobs':
        return localizations.agentJobs;
      case 'aiagents':
        return localizations.aiAgents;
      case 'aichat':
        return localizations.aiChat;
      case 'applications':
        return localizations.applications;
      case 'approvals':
        return localizations.approvals;
      case 'assessments':
        return localizations.assessments;
      case 'assets':
        return localizations.assets;
      case 'assistanthours':
        return localizations.assistantHours;
      case 'automation':
        return localizations.automation;
      case 'balancesheet':
        return localizations.balanceSheet;
      case 'balancesummary':
        return localizations.balanceSummary;
      case 'billofmaterials':
        return localizations.billOfMaterials;
      case 'campaigns':
        return localizations.campaigns;
      case 'catalog':
        return localizations.catalog;
      case 'categories':
        return localizations.categories;
      case 'checkin':
        return localizations.checkIn;
      case 'checkout':
        return localizations.checkOut;
      case 'clients':
        return localizations.clients;
      case 'company':
        return localizations.company;
      case 'content':
        return localizations.content;
      case 'contentplans':
        return localizations.contentPlans;
      case 'courselist':
        return localizations.courseList;
      case 'coursemedia':
        return localizations.courseMedia;
      case 'courses':
        return localizations.courses;
      case 'courseviewer':
        return localizations.courseViewer;
      case 'crm':
        return localizations.crm;
      case 'customers':
        return localizations.customers;
      case 'emailsequences':
        return localizations.emailSequences;
      case 'employees':
        return localizations.employees;
      case 'engagements':
        return localizations.engagements;
      case 'equipment':
        return localizations.equipment;
      case 'equipmenttypes':
        return localizations.equipmentTypes;
      case 'housekeeping':
        return localizations.housekeeping;
      case 'incomingpayments':
        return localizations.incomingPayments;
      case 'incomingshipments':
        return localizations.incomingShipments;
      case 'inout':
        return localizations.inOut;
      case 'inventory':
        return localizations.inventory;
      case 'itemtypes':
        return localizations.itemTypes;
      case 'knowledge':
        return localizations.knowledge;
      case 'landingpages':
        return localizations.landingPages;
      case 'leads':
        return localizations.leads;
      case 'ledger':
        return localizations.ledger;
      case 'ledgeraccounts':
        return localizations.ledgerAccounts;
      case 'ledgerjournals':
        return localizations.ledgerJournals;
      case 'ledgertransaction':
        return localizations.ledgerTransaction;
      case 'llmusage':
        return localizations.llmUsage;
      case 'main':
        return localizations.main;
      case 'manufacturing':
        return localizations.manufacturing;
      case 'marketing':
        return localizations.marketing;
      case 'messages':
        return localizations.messages;
      case 'mycompany':
        return localizations.myCompany;
      case 'myhotel':
        return localizations.myHotel;
      case 'mytodotasks':
        return localizations.myTodoTasks;
      case 'occupancyadr':
        return localizations.occupancyAdr;
      case 'opportunities':
        return localizations.opportunities;
      case 'orders':
        return localizations.orders;
      case 'organization':
        return localizations.organization;
      case 'outgoingpayments':
        return localizations.outgoingPayments;
      case 'outgoingshipments':
        return localizations.outgoingShipments;
      case 'outreach':
        return localizations.outreach;
      case 'owners':
        return localizations.owners;
      case 'paymenttypes':
        return localizations.paymentTypes;
      case 'personas':
        return localizations.personas;
      case 'pickup':
        return localizations.pickup;
      case 'pickupreturn':
        return localizations.pickupReturn;
      case 'pipeline':
        return localizations.pipeline;
      case 'planselection':
        return localizations.planSelection;
      case 'platforms':
        return localizations.platforms;
      case 'products':
        return localizations.products;
      case 'purchaseinvoices':
        return localizations.purchaseInvoices;
      case 'purchaseorders':
        return localizations.purchaseOrders;
      case 'rates':
        return localizations.rates;
      case 'rentals':
        return localizations.rentals;
      case 'reports':
        return localizations.reports;
      case 'requests':
        return localizations.requests;
      case 'reservations':
        return localizations.reservations;
      case 'return':
        return localizations.returnLabel;
      case 'revenueexpenses':
        return localizations.revenueExpense;
      case 'rooms':
        return localizations.rooms;
      case 'roomtypes':
        return localizations.roomTypes;
      case 'routings':
        return localizations.routings;
      case 'sales':
        return localizations.sales;
      case 'salesinvoices':
        return localizations.salesInvoices;
      case 'salesorders':
        return localizations.salesOrders;
      case 'sendqueue':
        return localizations.sendQueue;
      case 'setup':
        return localizations.setUp;
      case 'staff':
        return localizations.staff;
      case 'statistics':
        return localizations.statistics;
      case 'subscriptions':
        return localizations.subscriptions;
      case 'suppliers':
        return localizations.suppliers;
      case 'systemsetup':
        return localizations.systemSetup;
      case 'takeacourse':
        return localizations.takeACourse;
      case 'tasks':
        return localizations.tasks;
      case 'toolsintegrations':
        return localizations.toolsIntegrations;
      case 'transactions':
        return localizations.transactions;
      case 'users':
        return localizations.users;
      case 'utilisation':
        return localizations.utilisation;
      case 'web':
        return localizations.web;
      case 'webforms':
        return localizations.webForms;
      case 'website':
        return localizations.website;
      case 'websitegenerator':
        return localizations.websiteGenerator;
      case 'websitetranslation':
        return localizations.websiteTranslation;
      case 'whlocations':
        return localizations.whLocations;
      case 'wiki':
        return localizations.wiki;
      case 'workorders':
        return localizations.workOrders;
      default:
        return title;
    }
  }
}

/// Verticals without a ledger: currency / accounting-year start are hidden and
/// defaulted to USD and January.
const List<String> appsWithoutAccounting = ['AppMarketing', 'AppAgents'];

bool showAccountingSetup(String applicationId) =>
    !appsWithoutAccounting.contains(applicationId);
