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
  });
  test('itemTypes', () {
    String json1 = itemTypesToJson(itemTypes);
    ItemTypes newObj = itemTypesFromJson(json1);
    expect(itemTypesToJson(newObj), itemTypesToJson(itemTypes));
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
  });

  test('product', () {
    String json1 = productToJson(product);
    Product newObj = productFromJson(json1);
    expect(productToJson(newObj), productToJson(product));
    String json2 = productsToJson(products);
    List<Product> newObjs = productsFromJson(json2);
    expect(productsToJson(newObjs), productsToJson(products));
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
  });

  test('authenticate', () {
    String json1 = authenticateToJson(authenticate);
    Authenticate newAuth = authenticateFromJson(json1);
    expect(authenticateToJson(newAuth), authenticateToJson(authenticate));
  });

  test('order', () {
    String json1 = orderToJson(order);
    Order neworder = orderFromJson(json1);
    expect(orderToJson(neworder), orderToJson(order));
    String json2 = ordersToJson(orders);
    List<Order> neworders = ordersFromJson(json2);
    expect(ordersToJson(neworders), ordersToJson(orders));
  });

  test('opportunity', () {
    String json1 = opportunityToJson(opportunity);
    Opportunity newopportunity = opportunityFromJson(json1);
    expect(opportunityToJson(newopportunity), opportunityToJson(opportunity));
    String json2 = opportunitiesToJson(opportunities);
    List<Opportunity> newopportunities = opportunitiesFromJson(json2);
    expect(opportunitiesToJson(newopportunities),
        opportunitiesToJson(opportunities));
  });
}
