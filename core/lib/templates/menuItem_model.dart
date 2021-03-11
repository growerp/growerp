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

const MENU_DASHBOARD = 0;
const MENU_COMPANY = 1;
const MENU_CRM = 2;
const MENU_CATALOG = 3;
const MENU_SALES = 4;
const MENU_PURCHASE = 5;
const MENU_ACCOUNTING = 6;
const MENU_ACCTSALES = 1;
const MENU_ACCTPURCHASE = 2;
const MENU_ACCTLEDGER = 3;

class MenuItem {
  int menuItemId;
  String image;
  String selectedImage;
  String title;
  String route;
  List readGroups;
  List writeGroups;

  MenuItem(
      {this.menuItemId,
      this.image,
      this.selectedImage,
      this.title,
      this.route,
      this.readGroups,
      this.writeGroups});

  @override
  String toString() => 'MenuItem name: $title [$menuItemId]';
}

List<MenuItem> menuItems = [
  MenuItem(
      menuItemId: 0,
      image: "assets/images/dashBoardGrey.png",
      selectedImage: "assets/images/dashBoard.png",
      title: "Main",
      route: '/home',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      menuItemId: 1,
      image: "assets/images/companyGrey.png",
      selectedImage: "assets/images/company.png",
      title: "Company",
      route: '/company',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 2,
      image: "assets/images/crmGrey.png",
      selectedImage: "assets/images/crm.png",
      title: "CRM",
      route: '/crm',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      menuItemId: 3,
      image: "assets/images/productsGrey.png",
      selectedImage: "assets/images/products.png",
      title: "Catalog",
      route: '/catalog',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 4,
      image: "assets/images/orderGrey.png",
      selectedImage: "assets/images/order.png",
      title: "Sales",
      route: '/sales',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 5,
      image: "assets/images/supplierGrey.png",
      selectedImage: "assets/images/supplier.png",
      title: "Purchase",
      route: '/purchase',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      menuItemId: 6,
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Accounting",
      route: '/accounting',
      readGroups: ["GROWERP_M_ADMIN"]),
];
List<MenuItem> acctMenuItems = [
  MenuItem(
      menuItemId: 1,
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "     Acct\nDashBoard",
      route: '/accounting',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      menuItemId: 2,
      image: "assets/images/orderGrey.png",
      selectedImage: "assets/images/order.png",
      title: " Acct\nSales",
      route: '/acctSales',
      readGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 3,
      image: "assets/images/supplierGrey.png",
      selectedImage: "assets/images/supplier.png",
      title: "    Acct\nPurchase",
      route: '/acctPurchase',
      readGroups: ["GROWERP_M_ADMIN"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 4,
      image: "assets/images/accountingGrey.png",
      selectedImage: "assets/images/accounting.png",
      title: "Ledger",
      route: '/ledger',
      readGroups: ["GROWERP_M_ADMIN"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 0,
      image: "assets/images/dashBoardGrey.png",
      selectedImage: "assets/images/dashBoard.png",
      title: "Main",
      route: '/home',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
/*  MenuItem(
      menuItemId: 5,
      image: "assets/images/supplierGrey.png",
      selectedImage: "assets/images/supplier.png",
      title: "Purchase",
      route: '/purchase',
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
*/
];
