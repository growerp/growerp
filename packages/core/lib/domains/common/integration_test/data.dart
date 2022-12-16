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

import 'dart:typed_data';
import 'package:decimal/decimal.dart';
import 'package:core/domains/domains.dart';

Company company = Company(
  name: "Main Company",
  currency: currencies[0],
  salesPerc: Decimal.parse("5"),
  vatPerc: Decimal.parse("20"),
  email: "testXXX@example.com",
  address: Address(
      address1: 'mountain Ally 223',
      address2: 'suite 23',
      postalCode: '90210',
      city: 'Los Angeles',
      province: 'California',
      country: countries[50].name),
  paymentMethod: PaymentMethod(
      creditCardNumber: '4012888888881881',
      creditCardType: CreditCardType.visa,
      expireMonth: '10',
      expireYear: '2026'),
);

User admin = User(
  firstName: "John",
  lastName: "Doe",
  email: "testXXX@example.com",
  userGroup: UserGroup.Admin,
);

List<Company> companies = [
  Company(name: 'companyName0', currency: Currency(description: 'Baht')),
  Company(name: 'companyName1', currency: Currency(description: 'Euro')),
  Company(name: 'companyName2', currency: Currency(description: 'Dollar')),
  Company(name: 'companyName3', currency: Currency(description: 'Euro')),
  Company(name: 'companyName4', currency: Currency(description: 'USD')),
  Company(name: 'companyName5', currency: Currency(description: 'Euro')),
  Company(name: 'companyName6', currency: Currency(description: 'USD')),
];

List<User> administrators = [
  User(
    firstName: 'administrator1',
    lastName: 'last Name1',
    userGroup: UserGroup.Admin,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '111111111111',
  ),
  User(
    firstName: 'administrator2',
    lastName: 'last Name2',
    userGroup: UserGroup.Admin,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '2222222222222',
  ),
  User(
    firstName: 'administrator3',
    lastName: 'last Name3',
    userGroup: UserGroup.Admin,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '3333333333',
  ),
  User(
    firstName: 'administrator4',
    lastName: 'last Name4',
    userGroup: UserGroup.Admin,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '4444444444',
  ),
  User(
    firstName: 'administrator5',
    lastName: 'last Name5',
    userGroup: UserGroup.Admin,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '5555555555',
  ),
  User(
    firstName: 'administrator6',
    lastName: 'last Name6',
    userGroup: UserGroup.Admin,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666',
  ),
];
List<User> employees = [
  User(
    firstName: 'employee1',
    lastName: 'last Name1',
    userGroup: UserGroup.Employee,
    companyName: company.name,
    userId: 'usernameXXX',
    email: 'emailXXX@example.org',
    telephoneNr: '444444444444',
  ),
  User(
    firstName: 'employee2',
    lastName: 'last Name2',
    userGroup: UserGroup.Employee,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '555555555555',
  ),
  User(
    firstName: 'employee3',
    lastName: 'last Name3',
    userGroup: UserGroup.Employee,
    companyName: company.name,
    userId: 'usernameXXX',
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666',
  ),
  User(
    firstName: 'employee4',
    lastName: 'last Name4',
    userGroup: UserGroup.Employee,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '777777777',
  ),
  User(
    firstName: 'employee5',
    lastName: 'last Name5',
    userGroup: UserGroup.Employee,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '888888888',
  ),
  User(
    firstName: 'employee6',
    lastName: 'last Name6',
    userGroup: UserGroup.Employee,
    companyName: company.name,
    email: 'emailXXX@example.org',
    telephoneNr: '9999999999',
  )
];

List<User> leads = [
  User(
    firstName: 'lead1',
    lastName: 'last Name 1',
    userGroup: UserGroup.Lead,
    companyName: 'Lead company 0',
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666666',
  ),
  User(
    firstName: 'lead2',
    lastName: 'last Name 2',
    userGroup: UserGroup.Lead,
    companyName: 'Lead company 1',
    email: 'emailXXX@example.org',
    telephoneNr: '77777777777777',
  ),
  User(
    firstName: 'lead3',
    lastName: 'last Name 3',
    userGroup: UserGroup.Lead,
    companyName: 'Lead company 2',
    email: 'emailXXX@example.org',
    telephoneNr: '888888888888888',
  ),
  User(
    firstName: 'lead4',
    lastName: 'last Name 4',
    userGroup: UserGroup.Lead,
    companyName: 'Lead company 3',
    email: 'emailXXX@example.org',
    telephoneNr: '9999999999',
  ),
  User(
    firstName: 'lead5',
    lastName: 'last Name 5',
    userGroup: UserGroup.Lead,
    companyName: 'Lead company 4',
    email: 'emailXXX@example.org',
    telephoneNr: '000000000000',
  ),
  User(
    firstName: 'lead6',
    lastName: 'last Name 6',
    userGroup: UserGroup.Lead,
    companyName: 'Lead company 5',
    email: 'emailXXX@example.org',
    telephoneNr: '11111111111111',
  ),
];

List<User> suppliers = [
  User(
    firstName: 'supplier1',
    lastName: 'last Name1',
    userGroup: UserGroup.Supplier,
    companyName: 'supplier company 3',
    email: 'emailXXX@example.org',
    telephoneNr: '99999999999999',
    companyAddress: Address(
        address1: 'beach Boulevar',
        address2: 'suite 2',
        postalCode: '30071',
        city: 'Trang',
        province: 'California',
        country: countries[3].name),
/*    companyPaymentMethod: PaymentMethod(
        creditCardNumber: '5555555555554444',
        creditCardType: CreditCardType.mc,
        expireMonth: '09',
        expireYear: '2025'),
*/
  ),
  User(
    firstName: 'supplier2',
    lastName: 'last Name2',
    userGroup: UserGroup.Supplier,
    companyName: 'supplier company 4',
    email: 'emailXXX@example.org',
    telephoneNr: '10101010101010',
  ),
  User(
    firstName: 'supplier3',
    lastName: 'last Name3',
    userGroup: UserGroup.Supplier,
    companyName: 'supplier company 4',
    email: 'emailXXX@example.org',
    telephoneNr: '99999999999999',
    companyAddress: Address(
        address1: 'beach Boulevar4',
        address2: 'suite 24',
        postalCode: '300714',
        city: 'Trang4',
        province: 'California4',
        country: countries[4].name),
/*    companyPaymentMethod: PaymentMethod(
        creditCardNumber: '2223003122003222',
        creditCardType: CreditCardType.mc,
        expireMonth: '10',
        expireYear: '2026'),
*/
  ),
  User(
    firstName: 'supplier4',
    lastName: 'last Name4',
    userGroup: UserGroup.Supplier,
    companyName: 'supplier company 5',
    email: 'emailXXX@example.org',
    telephoneNr: '202020202020',
  )
];
List<User> customers = [
  User(
    firstName: 'customer1',
    lastName: 'lastName1',
    userGroup: UserGroup.Customer,
    companyName: 'customer company1',
    email: 'emailXXX@example.org',
    telephoneNr: '111111111111',
    companyAddress: Address(
        address1: 'soi 5',
        address2: 'suite 23',
        postalCode: '30071',
        city: 'Pucket',
        province: 'California',
        country: countries[3].name),
    companyPaymentMethod: PaymentMethod(
        creditCardNumber: '5555555555554444',
        creditCardType: CreditCardType.mc,
        expireMonth: '11',
        expireYear: '2032'),
  ),
  User(
    firstName: 'customer2',
    lastName: 'lastName2',
    userGroup: UserGroup.Customer,
    companyName: 'customer company2',
    email: 'emailXXX@example.org',
    telephoneNr: '12121212121212',
    companyAddress: Address(
        address1: 'test street 44',
        address2: 'office 23',
        postalCode: '444444',
        city: 'Trang',
        province: 'Trang',
        country: countries[12].name),
    companyPaymentMethod: PaymentMethod(
        creditCardNumber: '2223003122003222',
        creditCardType: CreditCardType.mc,
        expireMonth: '4',
        expireYear: '2029'),
  )
];

List<Task> tasks = [
  Task(
    taskName: 'task1',
    status: 'In Progress',
    description: 'This is the description of the task1',
    rate: Decimal.parse('22'),
    timeEntries: [],
  ),
  Task(
    taskName: 'task2',
    status: 'In Progress',
    description: 'This is the description of the task2',
    rate: Decimal.parse('23'),
    timeEntries: [],
  )
];

List<TimeEntry> timeEntries = [
  TimeEntry(
      hours: Decimal.parse('4'),
      date: DateTime.now().subtract(Duration(days: 4))),
  TimeEntry(
      hours: Decimal.parse('3'),
      date: DateTime.now().subtract(Duration(days: 3))),
  TimeEntry(
      hours: Decimal.parse('2'),
      date: DateTime.now().subtract(Duration(days: 2)))
];

List<ChatRoom> chatRooms = [
  ChatRoom(chatRoomName: 'chat room 1'),
  ChatRoom(chatRoomName: 'chat room 2'),
  ChatRoom(chatRoomName: 'chat room 3'),
];

List<Opportunity> opportunities = [
  Opportunity(
    opportunityName: 'Dummy Opp Name 1',
    description: 'Dummmy descr 1',
    stageId: 'Prospecting',
    nextStep: 'testing1',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('10000'),
    estProbability: Decimal.parse('10'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 2',
    description: 'Dummmy descr2',
    stageId: 'Qualification',
    nextStep: 'testing2',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('40000'),
    estProbability: Decimal.parse('40'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 3',
    description: 'Dummmy descr 3',
    stageId: 'Demo',
    nextStep: 'testing3',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('30000'),
    estProbability: Decimal.parse('30'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 4',
    description: 'Dummmy descr4',
    stageId: 'Proposal',
    nextStep: 'testing4',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('40000'),
    estProbability: Decimal.parse('40'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 5',
    description: 'Dummmy descr 5',
    stageId: 'Quote',
    nextStep: 'testing5',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('50000'),
    estProbability: Decimal.parse('50'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 6',
    description: 'Dummmy descr6',
    stageId: 'Prospecting',
    nextStep: 'testing6',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('60000'),
    estProbability: Decimal.parse('60'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 7',
    description: 'Dummmy descr 7',
    stageId: 'Qualification',
    nextStep: 'testing7',
    employeeUser: administrators[0], // initial logged admin[0]
    leadUser: leads[0],
    estAmount: Decimal.parse('70000'),
    estProbability: Decimal.parse('70'),
  ),
  Opportunity(
    opportunityName: 'Dummy Opp Name 8',
    description: 'Dummmy descr8',
    stageId: 'Demo',
    nextStep: 'testing8',
    employeeUser: administrators[1],
    leadUser: leads[1],
    estAmount: Decimal.parse('80000'),
    estProbability: Decimal.parse('80'),
  ),
];

List<Category> categories = [
  Category(
      categoryName: 'Category1',
      description: 'Category1 description',
      image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits)),
  Category(
      categoryName: 'Category2',
      description: 'Category2 description',
      image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits)),
  Category(
      categoryName: 'Category3',
      description: 'Category3 description',
      image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits)),
  Category(
      categoryName: 'Category4 to be deleted',
      description: 'Category4 description',
      image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits)),
];

// products can only refer to category 0,1 or product test fails
List<Product> products = [
  Product(
    productName: 'This is product 1 : shippable',
    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('23.99'),
    listPrice: Decimal.parse('27.99'),
    categories: [categories[0]],
    productTypeId: productTypes[0], // must be zero: shippable good
    description: 'This is a dummy description of first product',
    useWarehouse: true,
  ),
  Product(
    productName: 'This is product 2 : shippable',
    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('73.99'),
    listPrice: Decimal.parse('73.99'),
    categories: [categories[0], categories[1]],
    productTypeId: productTypes[0], // must be zero: shippable good
    description: 'This is a dummy description of second product',
    useWarehouse: true,
  ),
  Product(
    productName: 'This is product 3 : rental',
    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('93.99'),
    listPrice: Decimal.parse('99.99'),
    categories: [categories[0]], // only category 0 or rental test fails
    productTypeId: productTypes[2],
    description: 'This is a dummy description of third product',
    useWarehouse: false,
  ),
  Product(
    productName: 'This is product 4 : service',
    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('22.44'),
    listPrice: Decimal.parse('25.44'),
    categories: [categories[1]],
    productTypeId: productTypes[1],
    description: 'This is the fourth product to be deleted',
    useWarehouse: false,
  ),
];

List<ItemType> salesItems = [
  ItemType(itemTypeId: 'slstype1', itemTypeName: 'slstype 1 description'),
  ItemType(itemTypeId: 'slstype2', itemTypeName: 'slstype 2 description'),
  ItemType(itemTypeId: 'slstype3', itemTypeName: 'slstype 3 description')
];
List<ItemType> purchaseItems = [
  ItemType(itemTypeId: 'purchtype1', itemTypeName: 'purchtype 1 description'),
  ItemType(itemTypeId: 'purchtype2', itemTypeName: 'purchtype 2 description'),
  ItemType(itemTypeId: 'purchtype3', itemTypeName: 'purchtype 3 description')
];

List<FinDoc> purchaseOrders = [
  FinDoc(
      sales: false,
      docType: FinDocType.order,
      description: 'The first order',
      otherUser: suppliers[0],
      items: [
        FinDocItem(
            description: products[0].productName,
            quantity: Decimal.parse('20'),
            price: Decimal.parse('7.21'))
      ]),
  FinDoc(
      sales: false,
      docType: FinDocType.order,
      description: 'The second order',
      otherUser: suppliers[1],
      items: [
        FinDocItem(
            description: products[1].productName,
            quantity: Decimal.parse('40'),
            price: Decimal.parse('17.21')),
      ]),
];
List<FinDoc> purchaseInvoices = [
  FinDoc(
      sales: false,
      docType: FinDocType.invoice,
      description: 'Invoice 1',
      otherUser: suppliers[0],
      grandTotal: Decimal.parse('144.2'),
      items: [
        FinDocItem(
            description: products[0].productName,
            quantity: Decimal.parse('20'),
            price: Decimal.parse('7.21'))
      ]),
  FinDoc(
      sales: false,
      docType: FinDocType.invoice,
      description: 'Invoice 2',
      otherUser: suppliers[1],
      grandTotal: Decimal.parse('688.4'),
      items: [
        FinDocItem(
            description: products[1].productName,
            quantity: Decimal.parse('40'),
            price: Decimal.parse('17.21')),
      ]),
  FinDoc(
      sales: false,
      docType: FinDocType.invoice,
      description: 'Invoice 3',
      otherUser: suppliers[1],
      grandTotal: Decimal.parse('448.4'),
      items: [
        FinDocItem(
            description: products[1].productName,
            quantity: Decimal.parse('40'),
            price: Decimal.parse('11.21')),
      ]),
  FinDoc(
      sales: false,
      docType: FinDocType.invoice,
      description: 'Invoice 4',
      otherUser: suppliers[1],
      grandTotal: Decimal.parse('112.10'),
      items: [
        FinDocItem(
            description: products[0].productName,
            quantity: Decimal.parse('10'),
            price: Decimal.parse('11.21'))
      ]),
  FinDoc(
      sales: false,
      docType: FinDocType.invoice,
      description: 'Invoice 5',
      otherUser: suppliers[0],
      grandTotal: Decimal.parse('1660.5'),
      items: [
        FinDocItem(
            description: products[1].productName,
            quantity: Decimal.parse('50'),
            price: Decimal.parse('33.21')),
      ]),
];

List<FinDoc> purchasePayments = [
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("22.22"),
    items: [FinDocItem(itemTypeName: 'Product')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("33.33"),
    items: [FinDocItem(itemTypeName: 'Rental')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("44.44"),
    items: [FinDocItem(itemTypeName: 'VAT')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("55.55"),
    items: [FinDocItem(itemTypeName: 'Sales Tax')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("66.66"),
    items: [FinDocItem(itemTypeName: 'Rental')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("77.77"),
    items: [FinDocItem(itemTypeName: 'VAT')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("88.88"),
    items: [FinDocItem(itemTypeName: 'Sales Tax')],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("9.99"),
    items: [FinDocItem(itemTypeName: 'Product')],
  ),
];
List<FinDoc> salesPayments = [
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("33.22"),
    items: [FinDocItem(itemTypeName: 'Service Product')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("44.11"),
    items: [FinDocItem(itemTypeName: 'Tax')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("55.11"),
    items: [FinDocItem(itemTypeName: 'Ship')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("66.11"),
    items: [FinDocItem(itemTypeName: 'VAT')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("11.11"),
    items: [FinDocItem(itemTypeName: 'Tax')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("22.22"),
    items: [FinDocItem(itemTypeName: 'Service Product')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("33.33"),
    items: [FinDocItem(itemTypeName: 'VAT')],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("44.44"),
    items: [FinDocItem(itemTypeName: 'Ship')],
  ),
];

List<FinDoc> salesOrders = [
  FinDoc(
      sales: true,
      docType: FinDocType.order,
      description: 'The first sales order',
      otherUser: customers[0],
      items: [
        FinDocItem(
          description: products[0].productName,
          price: products[0].price,
          quantity: Decimal.parse('20'),
        ),
        FinDocItem(
          description: products[1].productName,
          price: products[1].price,
          quantity: Decimal.parse('40'),
        ),
      ]),
];

List<FinDoc> salesInvoices = [
  FinDoc(
      sales: true,
      docType: FinDocType.invoice,
      description: 'The first sales invoice',
      otherUser: customers[0],
      grandTotal: Decimal.parse('3439.4'),
      items: [
        FinDocItem(
          description: products[0].productName,
          price: products[0].price,
          quantity: Decimal.parse('20'),
        ),
        FinDocItem(
          description: products[1].productName,
          price: products[1].price,
          quantity: Decimal.parse('40'),
        ),
      ]),
  FinDoc(
      sales: true,
      docType: FinDocType.invoice,
      description: 'The second sales invoice',
      otherUser: customers[1],
      grandTotal: Decimal.parse('1939.4'),
      items: [
        FinDocItem(
          description: products[1].productName,
          price: products[1].price,
          quantity: Decimal.parse('10'),
        ),
        FinDocItem(
          description: products[0].productName,
          price: products[0].price,
          quantity: Decimal.parse('50'),
        ),
      ]),
];

List<FinDoc> rentalSalesOrders = [
  FinDoc(
      sales: false,
      docType: FinDocType.order,
      description: 'The first rental sales order',
      otherUser: customers[0],
      items: [
        FinDocItem(
          description: products[2].productName,
          price: products[2].price,
          quantity: Decimal.parse('2'), // nuber of days
          rentalFromDate: DateTime.now().add(Duration(days: 2)),
          rentalThruDate: DateTime.now().add(Duration(days: 4)),
        ),
      ]),
];

List<Location> warehouseLocations = [
  Location(locationName: 'For purchase order 0'),
  Location(locationName: 'For purchase order 1'),
  Location(locationName: 'For purchase order 2'),
  Location(locationName: 'For purchase order 3'),
];
// assets can only refer to product 0 and 1 or asset test fails
List<Asset> assets = [
  Asset(
    assetName: 'asset name 1',
    availableToPromise: Decimal.parse('100'),
    quantityOnHand: Decimal.parse('100'),
    product: products[0],
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(Duration(days: 4)),
  ),
  Asset(
    assetName: 'asset name 2',
    availableToPromise: Decimal.parse('200'),
    quantityOnHand: Decimal.parse('200'),
    product: products[1],
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(Duration(days: 4)),
  ),
  Asset(
    assetName: 'asset name 3 for rental',
    availableToPromise: Decimal.parse('1'),
    quantityOnHand: Decimal.parse('1'),
    product: products[2], // only products 2 or rental test fails
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(Duration(days: 4)),
  ),
  Asset(
    assetName: 'asset name 4 to be deleted',
    availableToPromise: Decimal.parse('400'),
    quantityOnHand: Decimal.parse('400'),
    product: products[0],
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(Duration(days: 4)),
  ),
];
