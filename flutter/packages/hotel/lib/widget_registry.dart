/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import 'package:flutter/material.dart';

import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_website/growerp_website.dart';

import 'views/accounting_form.dart';
import 'views/gantt_form.dart';

/// Registry to map backend widget names to actual Flutter widgets
class WidgetRegistry {
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    switch (widgetName) {
      // Main
      case 'GanttForm':
        return const GanttForm();

      // Organization / MyHotel
      case 'ShowCompanyDialog':
        return ShowCompanyDialog(Company(role: Role.company), dialog: false);
      case 'UserListCompany':
        return UserList(key: _getKey(args), role: Role.company);
      case 'WebsiteDialog':
        return const WebsiteDialog();

      // Rooms
      case 'AssetList':
        return const AssetList();
      case 'ProductList':
        return const ProductList();

      // Reservations
      case 'SalesOrderRentalList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.order,
          onlyRental: true,
        );
      case 'CompanyUserListCustomer':
        return CompanyUserList(key: _getKey(args), role: Role.customer);
      case 'PurchaseOrderList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.order,
        );
      case 'CompanyUserListSupplier':
        return CompanyUserList(key: _getKey(args), role: Role.supplier);

      // CheckIn/Out
      case 'CheckInList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.order,
          onlyRental: true,
          status: FinDocStatusVal.created,
        );
      case 'CheckOutList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.order,
          onlyRental: true,
          status: FinDocStatusVal.approved,
        );

      // Accounting Variants (Reused)
      case 'SalesInvoiceList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.invoice,
        );
      case 'SalesPaymentList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.payment,
        );
      case 'PurchaseInvoiceList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.invoice,
        );
      case 'PurchasePaymentList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.payment,
        );

      // Accounting Specific
      case 'AccountingForm':
        return const AccountingForm();
      case 'LedgerTreeForm':
        return const LedgerTreeForm();
      case 'GlAccountList':
        return const GlAccountList();
      case 'LedgerJournalList':
        return LedgerJournalList(key: _getKey(args));
      case 'TransactionList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.transaction,
        );
      case 'RevenueExpenseChart':
        return const RevenueExpenseChart();
      case 'BalanceSheetForm':
        return const BalanceSheetForm();
      case 'BalanceSummaryList':
        return const BalanceSummaryList();
      case 'TimePeriodListForm':
        return const TimePeriodListForm();
      case 'ItemTypeList':
        return const ItemTypeList();
      case 'PaymentTypeList':
        return const PaymentTypeList();

      // Common
      case 'UserList':
        return UserList(key: _getKey(args), role: _parseRole(args?['role']));
      case 'UserListCustomer':
        return UserList(key: _getKey(args), role: Role.customer);
      case 'UserListSupplier':
        return UserList(key: _getKey(args), role: Role.supplier);
      case 'UserListLead':
        return UserList(key: _getKey(args), role: Role.lead);
      case 'UserListEmployee':
        return UserList(key: _getKey(args), role: Role.company);

      default:
        // Default fallback
        debugPrint('WidgetRegistry: Widget $widgetName not found');
        return Center(child: Text("Widget $widgetName not found"));
    }
  }

  static Key? _getKey(Map<String, dynamic>? args) {
    if (args != null && args.containsKey('key')) {
      return Key(args['key']);
    }
    return null;
  }

  static Role _parseRole(String? roleName) {
    if (roleName == null) return Role.unknown;
    try {
      return Role.values.firstWhere(
        (e) => e.name.toLowerCase() == roleName.toLowerCase(),
        orElse: () => Role.unknown,
      );
    } catch (_) {
      return Role.unknown;
    }
  }
}
