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

import '../routing_constants.dart';

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
      menuItemId: 100,
      image: "assets/images/dashBoardGrey.png",
      selectedImage: "assets/images/dashBoard.png",
      title: "DashBoard",
      route: HomeRoute,
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      menuItemId: 200,
      image: "assets/images/usersGrey.png",
      selectedImage: "assets/images/users.png",
      title: "Employees",
      route: UsersRoute,
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 300,
      image: "assets/images/aboutGrey.png",
      selectedImage: "assets/images/about.png",
      title: "About",
      route: AboutRoute,
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"]),
  MenuItem(
      menuItemId: 400,
      image: "assets/images/productsGrey.png",
      selectedImage: "assets/images/products.png",
      title: "Products",
      route: ProductsRoute,
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 500,
      image: "assets/images/categoryGrey.png",
      selectedImage: "assets/images/category.png",
      title: "Categories",
      route: CategoriesRoute,
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
  MenuItem(
      menuItemId: 600,
      image: "assets/images/orderGrey.png",
      selectedImage: "assets/images/order.png",
      title: "Orders",
      route: OrdersRoute,
      readGroups: ["GROWERP_M_ADMIN", "GROWERP_M_EMPLOYEE"],
      writeGroups: ["GROWERP_M_ADMIN"]),
];
