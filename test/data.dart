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

import 'package:models/models.dart';
import 'package:decimal/decimal.dart';
import 'dart:math';

final String randomString4 = Random().nextInt(9999).toString();

User user = userFromJson('''
  {"user": {"firstName": "dummyFirstName",
            "lastName": "dummyLastName",
            "email": "dummy@example.com",
            "name": "dummyUsername",
            "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==",
            "userGroupId":"GROWERP_M_ADMIN"
            }
  }
''');
User customer = userFromJson('''
  {"user": {"firstName": "dummyCustomerName",
            "lastName": "dummyCustomerLastName",
            "email": "customer@example.com",
            "name": "dummyCustomername",
            "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==",
            "userGroupId":"GROWERP_M_CUSTOMER"
            }
  }
''');
List<User> users = usersFromJson('''
  {"users": [
      { "partyId": "12345",
        "firstName": "dummyFirstName",
        "lastName": "dummyLastName",
        "email": "dummy@example.com",
        "name": "dummyUsername",
        "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==",
        "userGroupId":"GROWERP_M_ADMIN"
        },
      { "partyId": "12346",
        "firstName": "dummyFirstName",
        "lastName": "dummyLastName",
        "email": "dummy@example.com",
        "name": "dummyUsername",
        "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==",
        "userGroupId":"GROWERP_M_ADMIN"
        }
  ]}
''');

Company company = companyFromJson('''
    {  "company": {"name": "Dummy Company Name 2",
                  "partyId": "100001",
                  "currency": "dummyCurrency",
                  "classificationId": "AppEcommerceShop",
                  "classificationDescr": "App for Ecommerce and shop",
                  "email": "dummy@example.com",
      "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
      }
    }
''');
List<Company> companies = companiesFromJson('''
  {"companies": [
      {"name": "Dummy Company Name",
        "partyId": "100001",
        "currency": "dummyCurrency",
        "classificationId": "AppEcommerceShop",
        "classificationDescr": "App for Ecommerce and shop",
        "email": "dummy@example.com",
        "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
      },
      {  "name": "Dummy Company Name 2",
          "partyId": "100002",
          "currency": "dummyCurrency",
          "classificationId": "AppEcommerceShop",
          "classificationDescr": "App for Ecommerce and shop",
          "email": "dummy@example.com",
      "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="
      }
  ]}
''');

Authenticate authenticateNoKey = authenticateFromJson('''
           {  "company": {"name": "Dummy Company Name",
                          "partyId": "100001",
                          "currencyId": "USD",
                          "classificationId": "AppEcommerceShop",
                          "classificationDescr": "App for Ecommerce and shop",
                          "email": "dummy@example.com",
      "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==",
                          "employees": [{"firstName": "dummyFirstName",
                       "lastName": "dummyLastName",
                       "email": "dummy@example.com",
                       "name": "dummyUsername",
                       "image": null,
                       "groupDescription": "Admin",
                       "userGroupId":"GROWERP_M_ADMIN"}]
                          },
              "user": {"firstName": "dummyFirstName",
                       "lastName": "dummyLastName",
                       "email": "dummy@example.com",
                       "name": "dummyUsername",
                       "image": null,
                       "groupDescription": "Admin",
                       "userGroupId":"GROWERP_M_ADMIN",
                       "language": null,
                       "country": null
                       },
              "apiKey": null
            }
      ''');
Authenticate authenticate = authenticateFromJson('''
           {  "company": {"name": "Dummy Company Name",
                          "partyId": "100001",
                          "currency": "dummyCurrency"
                          },
              "user": {"firstName": "dummyFirstName",
                       "lastName": "dummyLastName",
                       "email": "dummy@example.com",
                       "name": "dummyUsername",
        "image": "R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==",
                       "userGroupId":"GROWERP_M_ADMIN"
                       },
              "apiKey": "dummyKey............"
            }
      ''');

final String errorMessage = 'Dummy error message';
final String screenMessage = 'Dummy screen message';
final String companyName = 'Dummy Company Name';
final String companyPartyId = '100001';
final String companyEmailAddress = 'dummy@example.com';
final String firstName = 'dummyFirstName';
final String lastName = 'dummyLastName';
final String username = 'dummyUsername';
final String password = 'dummyPassword9!';
final String newPassword = 'dummyNewPassword9!';
final String emailAddress = 'dummy@example.com';
final String classificationId = 'AppEcommerceShop';
final String imageBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAH0lEQVR42mNk+M9Qz0BFwDhq4KiBowaOGjhq4Eg1EAAlJx3tIbLVagAAAABJRU5ErkJggg==";
Map register = {
  'username': username,
  'emailAddress': emailAddress,
  'newPassword': password,
  'firstName': firstName,
  'lastName': lastName,
  'companyName': companyName,
  'currencyId': currencyId,
  'companyEmailAddress': emailAddress,
  'classificationId': classificationId,
  'language': 'en_US',
  'environment': true, // true for production, false for debug
  'moquiSessionToken': null // need to be set when used!
};

final Catalog emptyCatalog = Catalog(categories: [], products: []);
final Catalog catalog = Catalog(categories: categories, products: products);

final ProductCategory category = categoryFromJson('''
  { "category":
      {"categoryId": "dummyFirstCategory", "categoryName": "1stCat",
      "description": null, 
      "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA="}
  }''');

final List<ProductCategory> categories = categoriesFromJson('''
    {
      "categories": [ 
      {"categoryId": "dummyFirstCategory", "categoryName": "1stCat",
      "description": "this is the long description of category first", 
      "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA="},
      {"categoryId": "secondCategory", "categoryName": "This is the second category",
      "description": "this is the long description of category second",
      "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA="}]
}''');
final List<Product> products = productsFromJson('''
{     "products": [
      {"productId": "dummyFirstProduct", "productName": "This is the first product",
      "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA=",
      "price": "23.99", "productCategoryId": "dummyFirstCategory",
      "description": "This is a dummy description of first product"},
      {"productId": "secondProduct", "productName": "This is the second product",
       "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA=",
       "price": "17.13", "productCategoryId": "dummyFirstCategory",
       "description": "This is a dummy description of second product"},
      {"productId": "thirdProduct", "productName": "This is the third product",
       "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA=",
       "price": "12.33", "productCategoryId": "secondCategory",
       "description": "This is a dummy description of third product"}]
}
    ''');
final Product product = productFromJson('''
{ "product":
      {"productId": "secondProduct", "productName": "This is the second product",
       "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA=",
       "price": "17.13", "categoryId": "dummyFirstCategory",
       "description": "This is a dummy description"}
}    ''');
final String currencyId = 'USD';
final currencies = [
  "Thailand Baht [THB]",
  "Euro [EUR]",
  "United States Dollar [USD]"
];

final Order order = orderFromJson('''
  { "order":
    { "orderId": null, "orderStatusId": "OrderOpen", 
      "currencyUomId": "THB",
      "placedDate": null, "placedTime": null, "partyId": null,
      "firstName": "dummyFirstName", "lastName": "dummylastName",
      "grandTotal": "44.53", "table": null, "accommodationAreaId": null,
      "accommodationSpotId": null,
      "orderItems": [
        { "orderItemSeqId": "01", "productId": null, "description": "Cola",
          "quantity": "5", "price": "1.5"},
        { "orderItemSeqId": "02", "productId": null, "description": "Macaroni",
          "quantity": "3", "price": "4.5"}
   ]}}
''');
final List<Order> orders = ordersFromJson('''
  { "orders": [
    { "orderId": "00002", "orderStatusId": "OrderOpen", 
      "placedDate": null, "placedTime": null, "partyId": null,
      "firstName": "dummyFirstName", "lastName": "dummylastName",  
      "grandTotal": "44.53", "table": null, "accommodationAreaId": null,
      "accommodationSpotId": null,
      "orderItems": [
        { "orderItemSeqId": "01", "productId": null, "description": "Cola",
          "quantity": "5", "price": "1.5"},
        { "orderItemSeqId": "02", "productId": null, "description": "Macaroni",
          "quantity": "3", "price": "4.5"}
      ]},
    { "orderId": "00003", "orderStatusId": "OrderOpen", 
      "placedDate": null, "placedTime": null, "partyId": null,
      "firstName": "dummyFirstName", "lastName": "dummylastName",
      "grandTotal": "44.53", "table": null, "accommodationAreaId": null,
      "accommodationSpotId": null,
      "orderItems": [
        { "orderItemSeqId": "01", "productId": null, "description": "Cola",
          "quantity": "5", "price": "1.5"},
        { "orderItemSeqId": "02", "productId": null, "description": "Macaroni",
          "quantity": "3", "price": "4.5"}
      ]}
   ]}
''');
final Order emptyOrder = Order(orderItems: []);
final OrderItem orderItem1 = OrderItem(
    productId: "dummyFirstProduct",
    description: "This is the first product",
    quantity: Decimal.parse('5'),
    price: Decimal.parse('3.3'));
final OrderItem orderItem2 = OrderItem(
    productId: "dummySecondProduct",
    description: "This is the second product",
    quantity: Decimal.parse('3'),
    price: Decimal.parse('2.2'));
final Order totalOrder = Order(orderItems: [orderItem1, orderItem2]);
