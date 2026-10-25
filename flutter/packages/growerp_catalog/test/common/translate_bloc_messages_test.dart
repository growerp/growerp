import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_catalog/growerp_catalog.dart';

void main() {
  final en = lookupCatalogLocalizations(const Locale('en'));

  test('translateProductBlocMessage_keyWithParam_insertsParam', () {
    // Act
    final text = translateProductBlocMessage('productUpdateSuccess:Apple', en);
    // Assert
    expect(text, en.productUpdateSuccess('Apple'));
    expect(text, contains('Apple'));
  });

  test('translateProductBlocMessage_paramWithColon_keepsWholeParam', () {
    expect(
      translateProductBlocMessage('productAddSuccess:Apple: red', en),
      en.productAddSuccess('Apple: red'),
    );
  });

  test('translateCategoryBlocMessage_deleteKey_translates', () {
    expect(
      translateCategoryBlocMessage('categoryDeleteSuccess:Fruit', en),
      en.categoryDeleteSuccess('Fruit'),
    );
  });

  test('translateSubscriptionBlocMessage_plainKey_translates', () {
    expect(
      translateSubscriptionBlocMessage('subscriptionAddSuccess', en),
      en.subscriptionAddSuccess,
    );
  });

  test('translateBlocMessages_unknownOrBackendText_isShownAsIs', () {
    expect(
      translateProductBlocMessage('Name already used', en),
      'Name already used',
    );
    expect(
      translateCategoryBlocMessage('Categories imported', en),
      'Categories imported',
    );
  });

  test('translateBlocMessages_nullOrEmpty_isEmpty', () {
    expect(translateProductBlocMessage(null, en), '');
    expect(translateSubscriptionBlocMessage('', en), '');
  });
}
