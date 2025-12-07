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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_activity/growerp_activity.dart';
import 'package:growerp_sales/growerp_sales.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_outreach/growerp_outreach.dart';
import 'views/accounting_form.dart';
import 'views/plan_selection_form.dart';
import 'views/admin_dashboard_content.dart';

/// Registry to map backend widget names to actual Flutter widgets
class WidgetRegistry {
  static Widget getWidget(String widgetName, [Map<String, dynamic>? args]) {
    switch (widgetName) {
      // Dashboard
      case 'AdminDashboard':
        return const AdminDashboardContent();

      // Organization / Users
      case 'UserList':
        return UserList(key: _getKey(args), role: _parseRole(args?['role']));
      case 'ShowCompanyDialog':
        return ShowCompanyDialog(Company(), dialog: false);
      case 'WebsiteDialog':
        return const WebsiteDialog();

      // Outreach
      case 'CampaignListScreen':
        return const CampaignListScreen();
      case 'AutomationScreen':
        return const AutomationScreen();
      case 'PlatformConfigListScreen':
        return const PlatformConfigListScreen();
      case 'OutreachMessageList':
        return const OutreachMessageList();

      // Marketing
      case 'ContentPlanList':
        return const ContentPlanList();
      case 'SocialPostList':
        return const SocialPostList();
      case 'PersonaList':
        return const PersonaList();
      case 'LandingPageList':
        return const LandingPageList();
      case 'AssessmentList':
        return const AssessmentList();

      // CRM
      case 'ActivityList':
        return ActivityList(
          _parseActivityType(args?['activityType']),
          key: _getKey(args),
        );
      case 'OpportunityList':
        return const OpportunityList();

      // Catalog / Inventory
      case 'ProductList':
        return const ProductList();
      case 'AssetList':
        return const AssetList();
      case 'CategoryList':
        return const CategoryList();
      case 'SubscriptionList':
        return const SubscriptionList();
      case 'LocationList':
        return const LocationList();

      // Accounting / Orders (FinDoc) - specific variants
      case 'SalesOrderList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.order,
        );
      case 'PurchaseOrderList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.order,
        );
      case 'SalesInvoiceList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.invoice,
        );
      case 'PurchaseInvoiceList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.invoice,
        );
      case 'OutgoingShipmentList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.shipment,
        );
      case 'IncomingShipmentList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.shipment,
        );

      // Payment variants
      case 'SalesPaymentList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.payment,
        );
      case 'PurchasePaymentList':
        return FinDocList(
          key: _getKey(args),
          sales: false,
          docType: FinDocType.payment,
        );
      // Transaction list
      case 'TransactionList':
        return FinDocList(
          key: _getKey(args),
          sales: true,
          docType: FinDocType.transaction,
        );
      // User list variants
      case 'UserListCustomer':
        return UserList(key: _getKey(args), role: Role.customer);
      case 'UserListSupplier':
        return UserList(key: _getKey(args), role: Role.supplier);
      case 'UserListLead':
        return UserList(key: _getKey(args), role: Role.lead);
      case 'UserListEmployee':
        return UserList(key: _getKey(args), role: Role.company);
      case 'FinDocList':
        return FinDocList(
          key: _getKey(args),
          sales: args?['sales'] ?? true,
          docType: _parseFinDocType(args?['docType']),
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
      case 'PlanSelectionForm':
        return const PlanSelectionForm();

      // Core / Misc
      case 'AboutForm':
        return const AboutForm();

      default:
        // Default fallback for unknown widgets
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

  static FinDocType _parseFinDocType(String? typeName) {
    if (typeName == null) return FinDocType.unknown;
    try {
      return FinDocType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeName.toLowerCase(),
        orElse: () => FinDocType.unknown,
      );
    } catch (_) {
      return FinDocType.unknown;
    }
  }

  static ActivityType _parseActivityType(String? typeName) {
    if (typeName == null) return ActivityType.todo;
    try {
      return ActivityType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeName.toLowerCase(),
        orElse: () => ActivityType.todo,
      );
    } catch (_) {
      return ActivityType.todo;
    }
  }
}
