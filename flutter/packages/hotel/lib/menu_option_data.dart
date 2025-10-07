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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_inventory/growerp_inventory.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';

import 'views/gantt_form.dart';

List<MenuOption> getMenuOptions(BuildContext context) {
  final localizations = CoreLocalizations.of(context)!;
  return [
    MenuOption(
      image: "packages/growerp_core/images/dashBoardGrey.png",
      selectedImage: "packages/growerp_core/images/dashBoard.png",
      title: localizations.main,
      route: '/',
      userGroups: [UserGroup.admin, UserGroup.employee],
      child: const GanttForm(),
    ),
    MenuOption(
      image: "packages/growerp_core/images/companyGrey.png",
      selectedImage: "packages/growerp_core/images/company.png",
      title: localizations.myHotel,
      route: '/myHotel',
      userGroups: [UserGroup.admin, UserGroup.employee],
      tabItems: [
        TabItem(
          form: ShowCompanyDialog(
            Company(role: Role.company),
            key: const Key('CompanyForm'),
            dialog: false,
      ),
          label: localizations.company,
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const UserList(key: Key('Employee'), role: Role.company),
          label: localizations.employees,
          icon: const Icon(Icons.school),
        ),
        TabItem(
          form: const WebsiteDialog(),
          label: localizations.website,
          icon: const Icon(Icons.webhook),
        ),
      ],
    ),
    MenuOption(
      image: "packages/growerp_core/images/single-bedGrey.png",
      selectedImage: "packages/growerp_core/images/single-bed.png",
      title: localizations.rooms,
      route: '/rooms',
      userGroups: [UserGroup.admin, UserGroup.employee],
      tabItems: [
        TabItem(
          form: const AssetList(),
          label: localizations.rooms,
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const ProductList(),
          label: localizations.roomTypes,
          icon: const Icon(Icons.home),
        ),
      ],
    ),
    MenuOption(
      image: "packages/growerp_core/images/reservationGrey.png",
      selectedImage: "packages/growerp_core/images/reservation.png",
      title: localizations.reservations,
      route: '/reservations',
      userGroups: [UserGroup.admin, UserGroup.employee],
      tabItems: [
        TabItem(
          form: const FinDocList(
            key: Key("SalesOrder"),
            sales: true,
            docType: FinDocType.order,
            onlyRental: true,
      ),
          label: localizations.reservations,
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyUserList(key: Key('Customer'), role: Role.customer),
          label: localizations.customers,
          icon: const Icon(Icons.school),
        ),
        TabItem(
          form: const FinDocList(
            key: Key('PurchaseOrder'),
            sales: false,
            docType: FinDocType.order,
      ),
          label: localizations.purchaseOrders,
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const CompanyUserList(key: Key('Supplier'), role: Role.supplier),
          label: localizations.suppliers,
          icon: const Icon(Icons.business),
        ),
      ],
    ),
    MenuOption(
      image: "packages/growerp_core/images/check-in-outGrey.png",
      selectedImage: "packages/growerp_core/images/check-in-out.png",
      title: localizations.inOut,
      route: '/checkInOut',
      userGroups: [UserGroup.admin, UserGroup.employee],
      tabItems: [
        TabItem(
          form: const FinDocList(
            key: Key("Check-In"),
            sales: true,
            docType: FinDocType.order,
            onlyRental: true,
            status: FinDocStatusVal.created,
      ),
          label: localizations.checkIn,
          icon: const Icon(Icons.home),
        ),
        TabItem(
          form: const FinDocList(
            key: Key("Check-Out"),
            sales: true,
            docType: FinDocType.order,
            onlyRental: true,
            status: FinDocStatusVal.approved,
      ),
          label: localizations.checkOut,
          icon: const Icon(Icons.home),
        ),
      ],
    ),
    MenuOption(
      image: "packages/growerp_core/images/accountingGrey.png",
      selectedImage: "packages/growerp_core/images/accounting.png",
      title: localizations.accounting,
      route: '/accounting',
      userGroups: [UserGroup.admin],
    ),
  ];
}
