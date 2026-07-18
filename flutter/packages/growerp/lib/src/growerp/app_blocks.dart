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

/// Registry of GrowERP building blocks that a vertical app can wire in.
///
/// Every field here is verified against a working app (admin/freelance) and the
/// menu seed data. The scaffold uses this table to generate `main.dart` wiring
/// (imports, bloc providers, localization delegates, widget registrations) and
/// the per-app menu seed rows. Widget names, provider signatures and delegate
/// availability are NOT guessed — a wrong widgetName fails silently until the
/// menu item is tapped, so all values come from existing registered code.
library;

/// A default top-level menu item contributed by a block.
///
/// [widgetName] MUST match a string the block's widget-registration function
/// actually registers (see e.g. get_catalog_widgets.dart).
class BlockMenuItem {
  final String title;
  final String route;
  final String iconName;
  final String widgetName;

  const BlockMenuItem({
    required this.title,
    required this.route,
    required this.iconName,
    required this.widgetName,
  });
}

/// Describes one wireable building block.
class AppBlock {
  /// Registry key, e.g. 'catalog' (used on the --blocks flag).
  final String key;

  /// Full Flutter package name, e.g. 'growerp_catalog'.
  final String package;

  /// Pub version constraint for the generated pubspec.
  final String version;

  /// Import URI for main.dart.
  final String importUri;

  /// One-line SMB-oriented description (also fed to the AI --describe prompt).
  final String description;

  /// Widget-registration function, e.g. 'getCatalogWidgets'. Null for blocks
  /// that register no menu-resolvable widgets (e.g. adk).
  final String? widgetsFn;

  /// Bloc-provider function, e.g. 'getCatalogBlocProviders'. Null when the
  /// block contributes no global providers.
  final String? blocProvidersFn;

  /// Whether [blocProvidersFn] takes (restClient, applicationId) vs (restClient).
  final bool providerTakesAppId;

  /// Localizations delegate expression, e.g. 'CatalogLocalizations.delegate'.
  /// Null for blocks that ship no localizations (marketing/outreach/courses).
  final String? localizationsDelegate;

  /// Default top-level menu item for this block. Null for blocks that add no
  /// menu entry of their own (e.g. adk, which is a dashboard FAB).
  final BlockMenuItem? menuItem;

  /// When true this block is the AI-assistant FAB (growerp_adk): it adds an
  /// import + a dashboard FAB via AdkChatDialog, no menu/provider/delegate.
  final bool isAdkFab;

  const AppBlock({
    required this.key,
    required this.package,
    required this.version,
    required this.importUri,
    required this.description,
    this.widgetsFn,
    this.blocProvidersFn,
    this.providerTakesAppId = false,
    this.localizationsDelegate,
    this.menuItem,
    this.isAdkFab = false,
  });
}

/// Blocks always included in every vertical (auth, company, base models).
/// growerp_core + growerp_models are dependencies of every block already, so
/// they are added to the pubspec directly by the scaffold.
const List<String> alwaysIncludedBlocks = ['user_company'];

/// Opinionated default block set for a minimal viable SMB vertical when
/// --blocks / --describe are not given: products + invoicing + tasks + AI chat.
const List<String> defaultBlocks = [
  'catalog',
  'order_accounting',
  'activity',
  'adk',
];

/// The building-block registry, keyed by block key.
const Map<String, AppBlock> appBlocks = {
  'user_company': AppBlock(
    key: 'user_company',
    package: 'growerp_user_company',
    version: '^1.9.0',
    importUri: 'package:growerp_user_company/growerp_user_company.dart',
    description:
        'Companies, employees, customers, suppliers and leads. Baseline for '
        'every vertical (login, company profile, user management).',
    widgetsFn: 'getUserCompanyWidgets',
    blocProvidersFn: 'getUserCompanyBlocProviders',
    providerTakesAppId: true,
    localizationsDelegate: 'UserCompanyLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'Organization',
      route: '/companies',
      iconName: 'business',
      widgetName: 'ShowCompanyDialog',
    ),
  ),
  'catalog': AppBlock(
    key: 'catalog',
    package: 'growerp_catalog',
    version: '^1.9.0',
    importUri: 'package:growerp_catalog/growerp_catalog.dart',
    description:
        'Products, categories and subscriptions. Use for any business that '
        'sells goods or services.',
    widgetsFn: 'getCatalogWidgets',
    blocProvidersFn: 'getCatalogBlocProviders',
    providerTakesAppId: true,
    localizationsDelegate: 'CatalogLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'Catalog',
      route: '/catalog',
      iconName: 'category',
      widgetName: 'ProductList',
    ),
  ),
  'inventory': AppBlock(
    key: 'inventory',
    package: 'growerp_inventory',
    version: '^1.9.0',
    importUri: 'package:growerp_inventory/growerp_inventory.dart',
    description:
        'Warehouse locations and fixed assets. Use for stock-holding retail or '
        'wholesale that tracks on-hand quantities.',
    widgetsFn: 'getInventoryWidgets',
    blocProvidersFn: 'getInventoryBlocProviders',
    providerTakesAppId: true,
    localizationsDelegate: 'InventoryLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'Inventory',
      route: '/inventory',
      iconName: 'warehouse',
      widgetName: 'LocationList',
    ),
  ),
  'order_accounting': AppBlock(
    key: 'order_accounting',
    package: 'growerp_order_accounting',
    version: '^1.9.0',
    importUri:
        'package:growerp_order_accounting/growerp_order_accounting.dart',
    description:
        'Sales/purchase orders, invoices, payments, shipments and the general '
        'ledger. The invoicing/accounting backbone of most verticals.',
    widgetsFn: 'getOrderAccountingWidgets',
    blocProvidersFn: 'getOrderAccountingBlocProviders',
    providerTakesAppId: true,
    localizationsDelegate: 'OrderAccountingLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'Orders',
      route: '/orders',
      iconName: 'shopping_cart',
      widgetName: 'SalesOrderList',
    ),
  ),
  'activity': AppBlock(
    key: 'activity',
    package: 'growerp_activity',
    version: '^1.8.1',
    importUri: 'package:growerp_activity/growerp_activity.dart',
    description:
        'Tasks, to-dos and activity tracking. Use for services businesses and '
        'anyone who works from a task list.',
    widgetsFn: 'getActivityWidgets',
    blocProvidersFn: 'getActivityBlocProviders',
    providerTakesAppId: true,
    localizationsDelegate: 'ActivityLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'Tasks',
      route: '/tasks',
      iconName: 'task',
      widgetName: 'ActivityList',
    ),
  ),
  'sales': AppBlock(
    key: 'sales',
    package: 'growerp_sales',
    version: '^1.9.0',
    importUri: 'package:growerp_sales/growerp_sales.dart',
    description:
        'CRM opportunities and sales pipeline. Use for sales-driven teams that '
        'manage a deal funnel.',
    widgetsFn: 'getSalesWidgets',
    blocProvidersFn: 'getSalesBlocProviders',
    providerTakesAppId: false,
    localizationsDelegate: 'SalesLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'CRM',
      route: '/crm',
      iconName: 'people',
      widgetName: 'OpportunityList',
    ),
  ),
  'website': AppBlock(
    key: 'website',
    package: 'growerp_website',
    version: '^1.9.0',
    importUri: 'package:growerp_website/growerp_website.dart',
    description:
        'Storefront website and web forms. Use for businesses that sell or '
        'capture leads online.',
    widgetsFn: 'getWebsiteWidgets',
    blocProvidersFn: 'getWebsiteBlocProviders',
    providerTakesAppId: false,
    localizationsDelegate: 'WebsiteLocalizations.delegate',
    menuItem: BlockMenuItem(
      title: 'Website',
      route: '/website',
      iconName: 'web',
      widgetName: 'WebsiteDialog',
    ),
  ),
  'marketing': AppBlock(
    key: 'marketing',
    package: 'growerp_marketing',
    version: '^1.9.0',
    importUri: 'package:growerp_marketing/growerp_marketing.dart',
    description:
        'Content plans, social content, personas, landing pages and email '
        'sequences. Use for content-led marketing.',
    widgetsFn: 'getMarketingWidgets',
    blocProvidersFn: 'getMarketingBlocProviders',
    providerTakesAppId: false,
    localizationsDelegate: null,
    menuItem: BlockMenuItem(
      title: 'Marketing',
      route: '/marketing',
      iconName: 'campaign',
      widgetName: 'ContentPlanList',
    ),
  ),
  'outreach': AppBlock(
    key: 'outreach',
    package: 'growerp_outreach',
    version: '^1.9.0',
    importUri: 'package:growerp_outreach/growerp_outreach.dart',
    description:
        'Multi-channel campaigns, automation and platform messaging. Use for '
        'agencies and outbound sales/marketing.',
    widgetsFn: 'getOutreachWidgets',
    blocProvidersFn: 'getOutreachBlocProviders',
    providerTakesAppId: false,
    localizationsDelegate: null,
    menuItem: BlockMenuItem(
      title: 'Outreach',
      route: '/outreach',
      iconName: 'send',
      widgetName: 'CampaignListScreen',
    ),
  ),
  'courses': AppBlock(
    key: 'courses',
    package: 'growerp_courses',
    version: '^1.9.0',
    importUri: 'package:growerp_courses/growerp_courses.dart',
    description:
        'Courses, media and participants. Use for education, training and '
        'e-learning verticals.',
    widgetsFn: 'getCoursesWidgets',
    blocProvidersFn: 'getCoursesBlocProviders',
    providerTakesAppId: false,
    localizationsDelegate: null,
    menuItem: BlockMenuItem(
      title: 'Courses',
      route: '/courses',
      iconName: 'school',
      widgetName: 'CourseList',
    ),
  ),
  'adk': AppBlock(
    key: 'adk',
    package: 'growerp_adk',
    version: '^1.0.0',
    importUri: 'package:growerp_adk/growerp_adk.dart',
    description:
        'AI assistant chat (floating button on the dashboard). Recommended on '
        'every vertical.',
    isAdkFab: true,
  ),
};

/// Validates a requested block key list against the registry.
/// Returns the list of unknown keys (empty when all valid).
List<String> unknownBlockKeys(List<String> keys) =>
    keys.where((k) => !appBlocks.containsKey(k)).toList();

/// Resolves the effective, de-duplicated block key list for an app:
/// always-included blocks first, then the requested blocks in order.
List<String> resolveBlocks(List<String> requested) {
  final result = <String>[];
  for (final k in [...alwaysIncludedBlocks, ...requested]) {
    if (!result.contains(k)) result.add(k);
  }
  return result;
}
