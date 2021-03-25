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

import 'package:models/@models.dart';
import 'data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user', () {
    String json1 = userToJson(user);
    User newObj = userFromJson(json1);
    expect(userToJson(newObj), userToJson(user));
    String json2 = usersToJson(users);
    List<User> newObjs = usersFromJson(json2);
    expect(usersToJson(newObjs), usersToJson(users));
    expect(user, user.copyWith());
  });
  test('itemTypes', () {
    String json2 = itemTypesToJson(itemTypes);
    ItemTypes newObjs = itemTypesFromJson(json2);
    expect(itemTypesToJson(newObjs), itemTypesToJson(itemTypes));
  });

  test('category', () {
    String json1 = categoryToJson(category);
    ProductCategory newObj = categoryFromJson(json1);
    expect(categoryToJson(newObj), categoryToJson(category));
    String json2 = categoriesToJson(categories);
    List<ProductCategory> newObjs = categoriesFromJson(json2);
    expect(categoriesToJson(newObjs), categoriesToJson(categories));
    List props = category.props;
    expect(props, category.props);
    String toString = category.toString();
    expect(toString, category.toString());
  });

  test('product', () {
    String json1 = productToJson(product);
    Product newObj = productFromJson(json1);
    expect(productToJson(newObj), productToJson(product));
    String json2 = productsToJson(products);
    List<Product> newObjs = productsFromJson(json2);
    expect(productsToJson(newObjs), productsToJson(products));
    List props = product.props;
    expect(props, product.props);
    String toString = product.toString();
    expect(toString, product.toString());
    expect(product, product.copyWith());
  });

  test('catalog', () {
    String json1 = catalogToJson(catalog);
    Catalog newObj = catalogFromJson(json1);
    expect(catalogToJson(newObj), catalogToJson(catalog));
  });

  test('company', () {
    String json1 = companyToJson(company);
    Company newObj = companyFromJson(json1);
    expect(companyToJson(newObj), companyToJson(company));
    String json2 = companiesToJson(companies);
    List<Company> newObjs = companiesFromJson(json2);
    expect(companiesToJson(newObjs), companiesToJson(companies));
    expect(company, company.copyWith());
  });

  test('authenticate', () {
    String json1 = authenticateToJson(authenticate);
    Authenticate newAuth = authenticateFromJson(json1);
    expect(authenticateToJson(newAuth), authenticateToJson(authenticate));
  });

  test('finDoc', () {
    String json1 = finDocToJson(finDoc);
    FinDoc newfinDoc = finDocFromJson(json1);
    expect(finDocToJson(newfinDoc), finDocToJson(finDoc));
    String json2 = finDocsToJson(finDocs);
    List<FinDoc> newfinDocs = finDocsFromJson(json2);
    expect(finDocsToJson(newfinDocs), finDocsToJson(finDocs));
    String toString = finDoc.toString();
    expect(toString, finDoc.toString());
    String itemString = finDoc.items[0].toString();
    expect(itemString, finDoc.items[0].toString());
    FinDoc testFinDoc = FinDoc();
    expect(testFinDoc.idIsNull(), true);
    expect(testFinDoc.id(), 'New');
    testFinDoc = FinDoc(docType: 'invoice', invoiceId: 'abc');
    expect(testFinDoc.id(), 'abc');
    testFinDoc = FinDoc(docType: 'payment', paymentId: 'abc');
    expect(testFinDoc.id(), 'abc');
    testFinDoc = FinDoc(docType: 'order', orderId: 'abc');
    expect(testFinDoc.id(), 'abc');
    testFinDoc = FinDoc(docType: 'transaction', transactionId: 'abc');
    expect(testFinDoc.id(), 'abc');
  });

  test('opportunity', () {
    String json1 = opportunityToJson(opportunity);
    Opportunity newopportunity = opportunityFromJson(json1);
    expect(opportunityToJson(newopportunity), opportunityToJson(opportunity));
    String json2 = opportunitiesToJson(opportunities);
    List<Opportunity> newopportunities = opportunitiesFromJson(json2);
    expect(opportunitiesToJson(newopportunities),
        opportunitiesToJson(opportunities));
    String toString = opportunity.toString();
    expect(toString, opportunity.toString());
    List props = opportunity.props;
    expect(props, opportunity.props);
    List testStages = opportunityStages;
    expect(testStages, opportunityStages);
  });
  test('currency', () {
    String json1 = currencyToJson(currencies[0]);
    Currency newcurrency = currencyFromJson(json1);
    expect(currencyToJson(newcurrency), currencyToJson(currencies[0]));
    String json2 = currenciesToJson(currencies);
    List<Currency> newcurrencies = currenciesFromJson(json2);
    expect(currenciesToJson(newcurrencies), currenciesToJson(currencies));
  });
}
