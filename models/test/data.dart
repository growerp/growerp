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

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:models/@models.dart';
import 'dart:math';

final String randomString4 = Random().nextInt(9999).toString();

Opportunity opportunity = opportunityFromJson('''
    {  "opportunity": {
                  "opportunityName": "Dummy Opp Name 2",
                  "description": "Dummmy descr",
                  "stageId": "Prospecting",
                  "nextStep": "testing",
                  "opportunityId": "33333",
                  "accountPartyId": "100001",
                  "leadPartyId": "100001",
                  "estAmount": "30000",
                  "estProbability": "30",
                  "fullName": "Jan de groot",
                  "email": "dummy@example.com"
      }
    }
''');
List<Opportunity> opportunities = [opportunity, opportunity];

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

List<ItemType> salesItems = [
  ItemType(itemTypeId: "slstype1", itemTypeName: "slstype 1 description"),
  ItemType(itemTypeId: "slstype2", itemTypeName: "slstype 2 description"),
  ItemType(itemTypeId: "slstype3", itemTypeName: "slstype 3 description")
];
List<ItemType> purchaseItems = [
  ItemType(itemTypeId: "purchtype1", itemTypeName: "purchtype 1 description"),
  ItemType(itemTypeId: "purchtype2", itemTypeName: "purchtype 2 description"),
  ItemType(itemTypeId: "purchtype3", itemTypeName: "purchtype 3 description")
];
List<int> list =
    'R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='.codeUnits;
Uint8List imageString = Uint8List.fromList(list);

Company company = Company(
  name: "Dummy Company Name 2",
  partyId: "100001",
  currencyId: "dummyCurrency",
  classificationId: "AppEcommerceShop",
  classificationDescr: "App for Ecommerce and shop",
  email: "dummy@example.com",
  image: imageString,
  vatPerc: Decimal.parse("0"),
  salesPerc: Decimal.parse("0"),
);

List<Company> companies = [
  company,
  Company(
    name: "Dummy Company Name 1",
    partyId: "100001",
    currencyId: "dummyCurrency",
    classificationId: "AppFreelancer",
    classificationDescr: "App for Ecommerce and shop",
    email: "dummy@example.com",
    vatPerc: Decimal.parse("22"),
    salesPerc: Decimal.parse("33"),
  )
];

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
  'currencyId': currencies[0],
  'companyEmailAddress': emailAddress,
  'classificationId': classificationId,
  'language': 'en_US',
  'environment': true, // true for production, false for debug
  'moquiSessionToken': null // need to be set when used!
};

final Catalog emptyCatalog = Catalog(categories: [], products: []);
final Catalog catalog = Catalog(categories: categories, products: products);

ProductCategory category = categoryFromJson('''
  { "category":
      {"categoryId": "dummyFirstCategory", "categoryName": "1stCat",
      "description": null, 
      "image": "R0lGODlhAQABAAAAACwAAAAAAQABAAA="}
  }''');

List<ProductCategory> categories = categoriesFromJson('''
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

final FinDoc finDoc = finDocFromJson('''
  { "finDoc":
    { "orderId": null, "sales": "true", "docType": "invoice", 
      "statusId": "FinDocCompleted", 
      "placedDate": "2012-02-27 13:27:00.123456z",
      "otherUser": { "partyId": "dummy"},
      "grandTotal": "44.53",
      "items": [
        { "itemSeqId": "01", "productId": null, "description": "Cola",
          "quantity": "5", "price": "1.5" , "deliveryDate": "2012-02-27 13:27:00.123456z"},
        { "itemSeqId": "02", "productId": null, "description": "Macaroni",
          "quantity": "3", "price": "4.5", "deliveryDate": null} 
   ]}}
''');
final List<FinDoc> finDocs = finDocsFromJson('''
  { "finDocs": [
    { "invoiceId": "00002", "statusId": "OrderOpen", "sales": "true",
      "placedDate": "2012-02-27 13:27:00.123456z",
      "otherUser": { "partyId": "dummy"},
      "grandTotal": "44.53",
      "items": [
        { "itemSeqId": "01", "productId": null, "description": "Cola",
          "quantity": "5", "price": "1.5", "deliveryDate": null},
        { "itemSeqId": "02", "productId": null, "description": "Macaroni",
          "quantity": "3", "price": "4.5", "deliveryDate": null}
      ]},
    { "paymentId": "00003", "statusId": "OrderOpen", "sales": "false",
      "placedDate": "2012-02-27 13:27:00.123456z",
      "otherUser": { "partyId": "dummy"},
      "grandTotal": "44.53", 
      "items": [
        { "itemSeqId": "01", "productId": null, "description": "Cola",
          "quantity": "5", "price": "1.5", "deliveryDate": null},
        { "itemSeqId": "02", "productId": null, "description": "Macaroni",
          "quantity": "3", "price": "4.5", "deliveryDate": null}
      ]}
   ]}
''');
