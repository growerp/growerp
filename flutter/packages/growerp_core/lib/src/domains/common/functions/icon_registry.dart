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

import 'package:flutter/material.dart';

/// Registry mapping icon names to Icon objects.
/// Icon names are stored in the database, and this registry
/// maps them to actual Flutter Icon widgets.
final Map<String, Icon> iconRegistry = {
  'home': const Icon(Icons.home),
  'business': const Icon(Icons.business),
  'school': const Icon(Icons.school),
  'settings': const Icon(Icons.settings),
  'security': const Icon(Icons.security),
  'cleaning_services': const Icon(Icons.cleaning_services),
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
  'autorenew': const Icon(Icons.autorenew),
  'schedule_send': const Icon(Icons.schedule_send),
  'connect_without_contact': const Icon(Icons.connect_without_contact),
  'hub': const Icon(Icons.hub),
  'smart_toy': const Icon(Icons.smart_toy),
  'rocket_launch': const Icon(Icons.rocket_launch),
  'outbox': const Icon(Icons.outbox),
  'mark_email_read': const Icon(Icons.mark_email_read),
  'mail_outline': const Icon(Icons.mail_outline),
  'forum': const Icon(Icons.forum),
  'chat': const Icon(Icons.chat),
  // Support app icons
  'apps': const Icon(Icons.apps),
  'http': const Icon(Icons.http),
  'scatter_plot': const Icon(Icons.scatter_plot),
  // Hotel app icons
  'king_bed': const Icon(Icons.king_bed),
  'book_online': const Icon(Icons.book_online),
  'luggage': const Icon(Icons.luggage),
  // User company icons
  'groups': const Icon(Icons.groups),
  'badge': const Icon(Icons.badge),
  'storefront': const Icon(Icons.storefront),
  'local_shipping': const Icon(Icons.local_shipping),
  'person_search': const Icon(Icons.person_search),
  'home_work': const Icon(Icons.home_work),
  'apartment': const Icon(Icons.apartment),
  'person': const Icon(Icons.person),
  'person_add': const Icon(Icons.person_add),
  'contacts': const Icon(Icons.contacts),
  'business_center': const Icon(Icons.business_center),
  'domain': const Icon(Icons.domain),
  'corporate_fare': const Icon(Icons.corporate_fare),
  'factory': const Icon(Icons.factory),
  'handshake': const Icon(Icons.handshake),
  'trending_up': const Icon(Icons.trending_up),
  'group_add': const Icon(Icons.group_add),
  'person_outline': const Icon(Icons.person_outline),
  'supervisor_account': const Icon(Icons.supervisor_account),
  'work': const Icon(Icons.work),
  'engineering': const Icon(Icons.engineering),
  // Additional icons used in seed data
  'receipt_long': const Icon(Icons.receipt_long),
  'receipt': const Icon(Icons.receipt),
  'input': const Icon(Icons.input),
  'output': const Icon(Icons.output),
  'psychology': const Icon(Icons.psychology),
  'assignment': const Icon(Icons.assignment),
  'group': const Icon(Icons.group),
  // Agent Control (ADK) icons — shown in the mobile bottom selection bar
  'dns': const Icon(Icons.dns), // MCP servers (server stack)
  'schedule': const Icon(Icons.schedule), // scheduled agent jobs (clock)
  'fact_check': const Icon(Icons.fact_check), // write approvals
  'history': const Icon(Icons.history), // agent action audit log
  'menu_book': const Icon(Icons.menu_book), // knowledge base

  // Referenced by menu seed data but previously missing here, so these items
  // fell back to the generic circle in the drawer, nav rail and dashboard.
  'auto_awesome': const Icon(Icons.auto_awesome), // generated content
  'construction': const Icon(Icons.construction),
  'dynamic_form': const Icon(Icons.dynamic_form), // web forms
  'hotel': const Icon(Icons.hotel),
  'memory': const Icon(Icons.memory), // infrastructure
  'play_circle_outline': const Icon(Icons.play_circle_outline), // course viewer
  'precision_manufacturing': const Icon(Icons.precision_manufacturing),
  'price_change': const Icon(Icons.price_change), // rental rates
  'route': const Icon(Icons.route), // manufacturing routings
  'schema': const Icon(Icons.schema), // bill of materials
  'thumb_up': const Icon(Icons.thumb_up), // engagements
  'translate': const Icon(Icons.translate),
  'travel_explore': const Icon(Icons.travel_explore), // website generator
  'tune': const Icon(Icons.tune), // system defaults
  'view_kanban': const Icon(Icons.view_kanban), // pipeline

  // Referenced by the Dart menu configurations of the package example apps.
  'account_balance_wallet': const Icon(Icons.account_balance_wallet),
  'attach_money': const Icon(Icons.attach_money),
  'bed': const Icon(Icons.bed),
  'calendar_today': const Icon(Icons.calendar_today),
  'check_circle': const Icon(Icons.check_circle),
  'event': const Icon(Icons.event),
  'folder': const Icon(Icons.folder),
  'layers': const Icon(Icons.layers),
  'location_on': const Icon(Icons.location_on),
  'login': const Icon(Icons.login),
  'money_off': const Icon(Icons.money_off),
  'outbound': const Icon(Icons.outbound),
  'palette': const Icon(Icons.palette),
  'payment': const Icon(Icons.payment),
  'payments': const Icon(Icons.payments),
  'play_circle': const Icon(Icons.play_circle),
  'summarize': const Icon(Icons.summarize),
};

/// Get an Icon by its name from the registry.
/// Returns null if the icon name is not found.
Icon? getIconByName(String? iconName) {
  if (iconName == null) return null;
  return iconRegistry[iconName];
}

/// Alias for getIconByName for consistency with widget code.
Icon? getIconFromRegistry(String? iconName) => getIconByName(iconName);
