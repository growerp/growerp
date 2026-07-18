/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_catalog.dart';

/// Returns widget mappings for the catalog package
Map<String, GrowerpWidgetBuilder> getCatalogWidgets() {
  return {
    'ProductList': (args) => ProductList(key: getKeyFromArgs(args)),
    'CategoryList': (args) => CategoryList(key: getKeyFromArgs(args)),
    'SubscriptionList': (args) => SubscriptionList(key: getKeyFromArgs(args)),
  };
}

/// Returns widget metadata with icons for the catalog package
List<WidgetMetadata> getCatalogWidgetsWithMetadata() {
  return [
    WidgetMetadata(
      widgetName: 'ProductList',
      description: 'List of products in the catalog',
      iconName: 'inventory',
      keywords: ['product', 'item', 'catalog', 'goods'],
      builder: (args) => ProductList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'CategoryList',
      description: 'List of product categories',
      iconName: 'category',
      keywords: ['category', 'classification', 'group'],
      builder: (args) => CategoryList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'SubscriptionList',
      description: 'List of subscriptions',
      iconName: 'subscriptions',
      keywords: ['subscription', 'recurring', 'membership'],
      builder: (args) => SubscriptionList(key: getKeyFromArgs(args)),
    ),
    WidgetMetadata(
      widgetName: 'ProductDialog',
      description: 'Create or edit a product. Pass productId to edit an '
          'existing product; omit it to create a new one.',
      iconName: 'inventory',
      keywords: ['add product', 'new product', 'create product', 'edit product', 'open product'],
      parameters: {
        'productId': 'open this product for editing; omit to create new',
        'productName': 'product name (prefill for create)',
        'description': 'description (prefill for create)',
        'price': 'list price (prefill for create)',
      },
      builder: (args) {
        final id = (args?['productId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) {
          return ProductDialog(entityFromArgs<Product>(args, Product.fromJson) ?? Product());
        }
        return AsyncRecordDialog<Product>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getProduct(
                productId: id, limit: 1, applicationId: ctx.read<String>());
            return r.products.isNotEmpty ? r.products.first : null;
          },
          onLoaded: (p) => ProductDialog(p),
        );
      },
    ),
    WidgetMetadata(
      widgetName: 'CategoryDialog',
      description: 'Create or edit a product category. Pass categoryId to edit '
          'an existing category; omit it to create a new one.',
      iconName: 'category',
      keywords: ['add category', 'new category', 'create category', 'edit category'],
      parameters: {
        'categoryId': 'open this category for editing; omit to create new',
        'categoryName': 'category name (prefill for create)',
        'description': 'description (prefill for create)',
      },
      builder: (args) {
        final id = (args?['categoryId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) {
          return CategoryDialog(entityFromArgs<Category>(args, Category.fromJson) ?? Category());
        }
        return AsyncRecordDialog<Category>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getCategory(
                searchString: id, limit: 1, applicationId: ctx.read<String>());
            return r.categories.isNotEmpty ? r.categories.first : null;
          },
          onLoaded: (c) => CategoryDialog(c),
        );
      },
    ),
    WidgetMetadata(
      widgetName: 'SubscriptionDialog',
      description: 'Create or edit a subscription. Pass subscriptionId to edit '
          'an existing subscription; omit it to create a new one.',
      iconName: 'subscriptions',
      keywords: ['add subscription', 'new subscription', 'edit subscription'],
      parameters: {'subscriptionId': 'open this subscription for editing; omit to create new'},
      builder: (args) {
        final id = (args?['subscriptionId'] ?? args?['id'])?.toString();
        if (id == null || id.isEmpty) return SubscriptionDialog(Subscription());
        return AsyncRecordDialog<Subscription>(
          fetch: (ctx) async {
            final r = await ctx.read<RestClient>().getSubscription(
                subscriptionId: id, limit: 1);
            return r.subscriptions.isNotEmpty ? r.subscriptions.first : null;
          },
          onLoaded: (s) => SubscriptionDialog(s),
        );
      },
    ),
  ];
}
