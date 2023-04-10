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

import 'package:decimal/decimal.dart';
import 'src/domains/domains.dart';

Company initialCompany = Company(
  name: "Main Company",
  role: Role.company,
  currency: currencies[3],
  email: "testXXX@example.com",
);

Company company = Company(
  name: "Updated Main Company",
  role: Role.company,
  currency: currencies[2],
  salesPerc: Decimal.parse("5"),
  vatPerc: Decimal.parse("20"),
  email: "testXXX@example.com",
  telephoneNr: '555555555555',
  address: Address(
      address1: 'mountain Ally 223',
      address2: 'suite 23',
      postalCode: '90210',
      city: 'Los Angeles',
      province: 'California',
      country: countries[50].name),
  paymentMethod: PaymentMethod(
      ccDescription: 'Visa**********1881 10/2026',
      creditCardNumber: '4012888888881881',
      creditCardType: CreditCardType.visa,
      expireMonth: '10',
      expireYear: '2026'),
);

User admin = User(
  firstName: "John",
  lastName: "Doe",
  email: "testXXX@example.com",
  userGroup: UserGroup.admin,
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
    loginName: 'adminXXX',
    userGroup: UserGroup.admin,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '111111111111',
  ),
  User(
    firstName: 'administrator2',
    lastName: 'last Name2',
    loginName: 'adminXXX',
    userGroup: UserGroup.admin,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '2222222222222',
  ),
  User(
    firstName: 'administrator3',
    lastName: 'last Name3',
    loginName: 'adminXXX',
    userGroup: UserGroup.admin,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '3333333333',
  ),
  User(
    firstName: 'administrator4',
    lastName: 'last Name4',
    loginName: 'adminXXX',
    userGroup: UserGroup.admin,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '4444444444',
  ),
  User(
    firstName: 'administrator5',
    lastName: 'last Name5',
    loginName: 'adminXXX',
    userGroup: UserGroup.admin,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '5555555555',
  ),
  User(
    firstName: 'administrator6',
    lastName: 'last Name6',
    loginName: 'adminXXX',
    userGroup: UserGroup.admin,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666',
  ),
];
List<User> employees = [
  User(
    firstName: 'employee1',
    lastName: 'last Name1',
    loginName: 'emplXXX',
    userGroup: UserGroup.employee,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '444444444444',
  ),
  User(
    firstName: 'employee2',
    lastName: 'last Name2',
    loginName: 'emplXXX',
    userGroup: UserGroup.employee,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '555555555555',
  ),
  User(
    firstName: 'employee3',
    lastName: 'last Name3',
    loginName: 'emplXXX',
    userGroup: UserGroup.employee,
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666',
  ),
  User(
    firstName: 'employee4',
    lastName: 'last Name4',
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '777777777',
  ),
  User(
    firstName: 'employee5',
    lastName: 'last Name5',
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '888888888',
  ),
  User(
    firstName: 'employee6',
    lastName: 'last Name6',
    company: company,
    email: 'emailXXX@example.org',
    telephoneNr: '9999999999',
  )
];

List<Company> leadCompanies = [
  Company(
    name: 'Lead company 1',
    role: Role.lead,
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666666',
  ),
  Company(
    name: 'Lead company 2',
    role: Role.lead,
    email: 'emailXXX@example.org',
    telephoneNr: '77777777777777',
  ),
  Company(
    name: 'Lead company 3',
    role: Role.lead,
    email: 'emailXXX@example.org',
    telephoneNr: '888888888888888',
  ),
  Company(
    name: 'Lead company 4',
    role: Role.lead,
    telephoneNr: '9999999999',
  ),
  Company(
    name: 'Lead company 5',
    role: Role.lead,
    telephoneNr: '000000000000',
  ),
  Company(
    name: 'Lead company 6',
    role: Role.lead,
    email: 'emailXXX@example.org',
    telephoneNr: '11111111111111',
  ),
];

List<Company> supplierCompanies = [
  Company(
    name: 'supplier company 1',
    role: Role.supplier,
    address: Address(
        address1: 'beach Boulevar',
        address2: 'suite 2',
        postalCode: '30071',
        city: 'Trang',
        province: 'California',
        country: countries[3].name),
    email: 'emailXXX@example.org',
    telephoneNr: '99999999999999',
  ),
  Company(
    name: 'supplier company 2',
    role: Role.supplier,
    telephoneNr: '10101010101010',
  ),
  Company(
    name: 'supplier company 3',
    role: Role.supplier,
    address: Address(
        address1: 'beach Boulevar4',
        address2: 'suite 24',
        postalCode: '300714',
        city: 'Trang4',
        province: 'California4',
        country: countries[4].name),
    email: 'emailXXX@example.org',
    telephoneNr: '99999999999999',
  ),
  Company(
    name: 'supplier company 4',
    role: Role.supplier,
    email: 'emailXXX@example.org',
    telephoneNr: '202020202020',
  )
];
List<Company> customerCompanies = [
  Company(
    name: 'customer company1',
    role: Role.customer,
  ),
  Company(
    name: 'customer company2',
    role: Role.customer,
    address: Address(
        address1: 'test street 44',
        address2: 'office 23',
        postalCode: '444444',
        city: 'Trang',
        province: 'Trang',
        country: countries[12].name),
    paymentMethod: PaymentMethod(
        ccDescription: 'Master Card**********3222 4/2029',
        creditCardNumber: '2223003122003222',
        creditCardType: CreditCardType.mc,
        expireMonth: '4',
        expireYear: '2029'),
    email: 'emailXXX@example.org',
    telephoneNr: '12121212121212',
  ),
  Company(
    name: 'customer company3',
    role: Role.customer,
    paymentMethod: PaymentMethod(
        ccDescription: 'Master Card**********4444 11/2032',
        creditCardNumber: '5555555555554444',
        creditCardType: CreditCardType.mc,
        expireMonth: '11',
        expireYear: '2032'),
    address: Address(
        address1: 'soi 5',
        address2: 'suite 23',
        postalCode: '30071',
        city: 'Pucket',
        province: 'California',
        country: countries[3].name),
    email: 'emailXXX@example.org',
    telephoneNr: '111111111111',
  ),
  Company(
    name: 'customer company4',
    role: Role.customer,
    address: Address(
        address1: 'test street 44',
        address2: 'office 23',
        postalCode: '444444',
        city: 'Trang',
        province: 'Trang',
        country: countries[12].name),
    paymentMethod: PaymentMethod(
        ccDescription: 'Master Card**********3222 4/2029',
        creditCardNumber: '2223003122003222',
        creditCardType: CreditCardType.mc,
        expireMonth: '4',
        expireYear: '2029'),
    email: 'emailXXX@example.org',
    telephoneNr: '12121212121212',
  )
];

List<User> leads = [
  User(
    firstName: 'lead1',
    lastName: 'last Name 1',
    company: leadCompanies[0],
    email: 'emailXXX@example.org',
    telephoneNr: '6666666666666',
  ),
  User(
    firstName: 'lead2',
    lastName: 'last Name 2',
    company: leadCompanies[1],
    email: 'emailXXX@example.org',
    telephoneNr: '77777777777777',
  ),
  User(
    firstName: 'lead3',
    lastName: 'last Name 3',
    company: leadCompanies[2],
    email: 'emailXXX@example.org',
    telephoneNr: '888888888888888',
  ),
  User(
    firstName: 'lead4',
    lastName: 'last Name 4',
    company: leadCompanies[3],
    telephoneNr: '9999999999',
  ),
  User(
    firstName: 'lead5',
    lastName: 'last Name 5',
    company: leadCompanies[4],
    telephoneNr: '000000000000',
  ),
  User(
    firstName: 'lead6',
    lastName: 'last Name 6',
    company: leadCompanies[5],
    email: 'emailXXX@example.org',
    telephoneNr: '11111111111111',
  ),
];

List<User> suppliers = [
  User(
    firstName: 'supplier1',
    lastName: 'last Name1',
    company: supplierCompanies[0],
    email: 'emailXXX@example.org',
    telephoneNr: '99999999999999',
  ),
  User(
    firstName: 'supplier2',
    lastName: 'last Name2',
    company: supplierCompanies[1],
    telephoneNr: '10101010101010',
  ),
  User(
    firstName: 'supplier3',
    lastName: 'last Name3',
    loginDisabled: true,
    company: supplierCompanies[2],
    email: 'emailXXX@example.org',
    telephoneNr: '99999999999999',
  ),
  User(
    firstName: 'supplier4',
    lastName: 'last Name4',
    company: supplierCompanies[3],
    email: 'emailXXX@example.org',
    telephoneNr: '202020202020',
  )
];
List<User> customers = [
  User(
    firstName: 'customer1',
    lastName: 'lastName1',
    company: customerCompanies[1],
    email: 'emailXXX@example.org',
    telephoneNr: '111111111111',
  ),
  User(
    firstName: 'customer2',
    lastName: 'lastName2',
    company: customerCompanies[2],
    email: 'emailXXX@example.org',
    telephoneNr: '12121212121212',
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
      date: DateTime.now().subtract(const Duration(days: 4))),
  TimeEntry(
      hours: Decimal.parse('3'),
      date: DateTime.now().subtract(const Duration(days: 3))),
  TimeEntry(
      hours: Decimal.parse('2'),
      date: DateTime.now().subtract(const Duration(days: 2)))
];

List<ChatRoom> chatRooms = [
  ChatRoom(chatRoomName: 'chat room 1'),
  ChatRoom(chatRoomName: 'chat room 2'),
  ChatRoom(chatRoomName: 'chat room 3'),
];

List<Category> categories = [
  Category(
    categoryName: 'Category1',
    description: 'Category1 description',
//    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
  ),
  Category(
    categoryName: 'Category2',
    description: 'Category2 description',
//    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
  ),
  Category(
    categoryName: 'Category3',
    description: 'Category3 description',
//    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
  ),
  Category(
    categoryName: 'Category4 to be deleted',
    description: 'Category4 description',
//    image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
  ),
];

// products can only refer to category 0,1 or product test fails
List<Product> products = [
  Product(
    productName: 'This is product 1 : shippable',
    //  image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('23.99'),
    listPrice: Decimal.parse('27.99'),
    categories: [categories[0]],
    productTypeId: productTypes[0], // must be zero: shippable good
    description: 'This is a dummy description of first product',
    useWarehouse: true,
  ),
  Product(
    productName: 'This is product 2 : shippable',
    //  image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('73.99'),
    listPrice: Decimal.parse('73.99'),
    categories: [categories[0], categories[1]],
    productTypeId: productTypes[0], // must be zero: shippable good
    description: 'This is a dummy description of second product',
    useWarehouse: true,
  ),
  Product(
    productName: 'This is product 3 : rental',
    //  image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
    price: Decimal.parse('93.99'),
    listPrice: Decimal.parse('99.99'),
    categories: [categories[0]], // only category 0 or rental test fails
    productTypeId: productTypes[2],
    description: 'This is a dummy description of third product',
    useWarehouse: false,
  ),
  Product(
    productName: 'This is product 4 : service',
    //  image: Uint8List.fromList('R0lGODlhAQABAAAAACwAAAAAAQABAAA='.codeUnits),
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
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Product'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("33.33"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Rental'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("44.44"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'VAT'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("55.55"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Sales Tax'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("66.66"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Rental'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("77.77"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'VAT'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("88.88"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Sales Tax'))],
  ),
  FinDoc(
    sales: false,
    docType: FinDocType.payment,
    otherUser: suppliers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("9.99"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Product'))],
  ),
];
List<FinDoc> salesPayments = [
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("33.22"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Service Product'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("44.11"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Tax'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("55.11"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Ship'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("66.11"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'VAT'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.cash,
    grandTotal: Decimal.parse("11.11"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Tax'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.creditcard,
    grandTotal: Decimal.parse("22.22"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Service Product'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[1],
    paymentInstrument: PaymentInstrument.bank,
    grandTotal: Decimal.parse("33.33"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'VAT'))],
  ),
  FinDoc(
    sales: true,
    docType: FinDocType.payment,
    otherUser: customers[0],
    paymentInstrument: PaymentInstrument.check,
    grandTotal: Decimal.parse("44.44"),
    items: [FinDocItem(itemType: ItemType(itemTypeName: 'Ship'))],
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
          rentalFromDate: DateTime.now().add(const Duration(days: 2)),
          rentalThruDate: DateTime.now().add(const Duration(days: 4)),
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
    receivedDate: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Asset(
    assetName: 'asset name 2',
    availableToPromise: Decimal.parse('200'),
    quantityOnHand: Decimal.parse('200'),
    product: products[1],
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Asset(
    assetName: 'asset name 3 for rental',
    availableToPromise: Decimal.parse('1'),
    quantityOnHand: Decimal.parse('1'),
    product: products[2], // only products 2 or rental test fails
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Asset(
    assetName: 'asset name 4 to be deleted',
    availableToPromise: Decimal.parse('400'),
    quantityOnHand: Decimal.parse('400'),
    product: products[0],
    statusId: assetStatusValues[0],
    receivedDate: DateTime.now().subtract(const Duration(days: 4)),
  ),
];
