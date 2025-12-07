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

import 'package:flutter/material.dart';

/// Registry mapping icon names to Icon objects.
/// Icon names are stored in the database, and this registry
/// maps them to actual Flutter Icon widgets.
final Map<String, Icon> iconRegistry = {
  'home': const Icon(Icons.home),
  'business': const Icon(Icons.business),
  'school': const Icon(Icons.school),
  'settings': const Icon(Icons.settings),
  'task': const Icon(Icons.task),
  'money': const Icon(Icons.money),
  'send': const Icon(Icons.send),
  'call_received': const Icon(Icons.call_received),
  'location_pin': const Icon(Icons.location_pin),
  'question_answer': const Icon(Icons.question_answer),
  'web': const Icon(Icons.web),
  'quiz': const Icon(Icons.quiz),
  'subscriptions': const Icon(Icons.subscriptions),
  'webhook': const Icon(Icons.webhook),
  'add': const Icon(Icons.add),
  'edit': const Icon(Icons.edit),
  'delete': const Icon(Icons.delete),
  'search': const Icon(Icons.search),
  'filter': const Icon(Icons.filter_list),
  'more': const Icon(Icons.more_vert),
  'back': const Icon(Icons.arrow_back),
  'forward': const Icon(Icons.arrow_forward),
  'up': const Icon(Icons.arrow_upward),
  'down': const Icon(Icons.arrow_downward),
  'check': const Icon(Icons.check),
  'close': const Icon(Icons.close),
  'menu': const Icon(Icons.menu),
  'info': const Icon(Icons.info),
  'warning': const Icon(Icons.warning),
  'error': const Icon(Icons.error),
  'success': const Icon(Icons.check_circle),
  'dashboard': const Icon(Icons.dashboard),
  // Accounting icons
  'shopping_cart': const Icon(Icons.shopping_cart),
  'shopping_bag': const Icon(Icons.shopping_bag),
  'account_balance': const Icon(Icons.account_balance),
  'account_tree': const Icon(Icons.account_tree),
  'format_list_bulleted': const Icon(Icons.format_list_bulleted),
  'view_list': const Icon(Icons.view_list),
  'checklist': const Icon(Icons.checklist),
  'assessment': const Icon(Icons.assessment),
  'list': const Icon(Icons.list),
  'arrow_back': const Icon(Icons.arrow_back),
  // Admin menu icons
  'people': const Icon(Icons.people),
  'inventory': const Icon(Icons.inventory),
  'warehouse': const Icon(Icons.warehouse),
  'category': const Icon(Icons.category),
  // Marketing & Outreach icons
  'campaign': const Icon(Icons.campaign),
  'share': const Icon(Icons.share),
  'public': const Icon(Icons.public),
  'message': const Icon(Icons.message),
  'settings_input_component': const Icon(Icons.settings_input_component),
};

/// Get an Icon by its name from the registry.
/// Returns null if the icon name is not found.
Icon? getIconByName(String? iconName) {
  if (iconName == null) return null;
  return iconRegistry[iconName];
}

/// Alias for getIconByName for consistency with widget code.
Icon? getIconFromRegistry(String? iconName) => getIconByName(iconName);
