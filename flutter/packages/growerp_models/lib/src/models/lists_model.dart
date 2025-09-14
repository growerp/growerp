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

// this file contains dummy models required by the retrofit package in order
// to be able to request lists in a map from the backend.
// [Map<String,List>]

import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'lists_model.g.dart';
part 'lists_model.freezed.dart';

@freezed
abstract class Countries with _$Countries {
  factory Countries({@Default([]) List<Country> countries}) = _Countries;
  Countries._();

  factory Countries.fromJson(Map<String, dynamic> json) =>
      _$CountriesFromJson(json);
}

@freezed
abstract class Uoms with _$Uoms {
  factory Uoms({@Default([]) List<Uom> uoms}) = _Uoms;
  Uoms._();

  factory Uoms.fromJson(Map<String, dynamic> json) => _$UomsFromJson(json);
}

@freezed
abstract class GlAccounts with _$GlAccounts {
  factory GlAccounts({@Default([]) List<GlAccount> glAccounts}) = _GlAccounts;
  GlAccounts._();

  factory GlAccounts.fromJson(Map<String, dynamic> json) =>
      _$GlAccountsFromJson(json);
}

@freezed
abstract class Categories with _$Categories {
  factory Categories({@Default([]) List<Category> categories}) = _Categories;
  Categories._();

  factory Categories.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFromJson(json);
}

@freezed
abstract class Products with _$Products {
  factory Products({@Default([]) List<Product> products}) = _Products;
  Products._();

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);
}

@freezed
abstract class ProductRentalDates with _$ProductRentalDates {
  factory ProductRentalDates({
    @Default([]) List<ProductRentalDate> productRentalDates,
  }) = _ProductRentalDates;
  ProductRentalDates._();

  factory ProductRentalDates.fromJson(Map<String, dynamic> json) =>
      _$ProductRentalDatesFromJson(json);
}

@freezed
abstract class Subscriptions with _$Subscriptions {
  factory Subscriptions({@Default([]) List<Subscription> subscriptions}) =
      _Subscriptions;
  Subscriptions._();

  factory Subscriptions.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionsFromJson(json);
}

@freezed
abstract class Assets with _$Assets {
  factory Assets({@Default([]) List<Asset> assets}) = _Assets;
  Assets._();

  factory Assets.fromJson(Map<String, dynamic> json) => _$AssetsFromJson(json);
}

@freezed
abstract class Applications with _$Applications {
  factory Applications({@Default([]) List<Application> applications}) =
      _Applications;
  Applications._();

  factory Applications.fromJson(Map<String, dynamic> json) =>
      _$ApplicationsFromJson(json);
}

@freezed
abstract class Users with _$Users {
  factory Users({@Default([]) List<User> users}) = _Users;
  Users._();

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);
}

@freezed
abstract class Companies with _$Companies {
  factory Companies({@Default([]) List<Company> companies}) = _Companies;
  Companies._();

  factory Companies.fromJson(Map<String, dynamic> json) =>
      _$CompaniesFromJson(json);
}

@freezed
abstract class RentalFullDates with _$RentalFullDates {
  factory RentalFullDates({@Default([]) List<String> rentalFullDates}) =
      _RentalFullDates;
  RentalFullDates._();

  factory RentalFullDates.fromJson(Map<String, dynamic> json) =>
      _$RentalFullDatesFromJson(json);
}

@freezed
abstract class FinDocs with _$FinDocs {
  factory FinDocs({@Default([]) List<FinDoc> finDocs}) = _FinDocs;
  FinDocs._();

  factory FinDocs.fromJson(Map<String, dynamic> json) =>
      _$FinDocsFromJson(json);
}

@freezed
abstract class FinDocItems with _$FinDocItems {
  factory FinDocItems({@Default([]) List<FinDocItem> finDocItems}) =
      _FinDocItems;
  FinDocItems._();

  factory FinDocItems.fromJson(Map<String, dynamic> json) =>
      _$FinDocItemsFromJson(json);
}

@freezed
abstract class ItemTypes with _$ItemTypes {
  factory ItemTypes({@Default([]) List<ItemType> itemTypes}) = _ItemTypes;
  ItemTypes._();

  factory ItemTypes.fromJson(Map<String, dynamic> json) =>
      _$ItemTypesFromJson(json);
}

@freezed
abstract class PaymentTypes with _$PaymentTypes {
  factory PaymentTypes({@Default([]) List<PaymentType> paymentTypes}) =
      _PaymentTypes;
  PaymentTypes._();

  factory PaymentTypes.fromJson(Map<String, dynamic> json) =>
      _$PaymentTypesFromJson(json);
}

@freezed
abstract class Locations with _$Locations {
  factory Locations({@Default([]) List<Location> locations}) = _Locations;
  Locations._();

  factory Locations.fromJson(Map<String, dynamic> json) =>
      _$LocationsFromJson(json);
}

@freezed
abstract class TimePeriods with _$TimePeriods {
  factory TimePeriods({@Default([]) List<TimePeriod> timePeriods}) =
      _TimePeriods;
  TimePeriods._();

  factory TimePeriods.fromJson(Map<String, dynamic> json) =>
      _$TimePeriodsFromJson(json);
}

@freezed
abstract class LedgerJournals with _$LedgerJournals {
  factory LedgerJournals({@Default([]) List<LedgerJournal> ledgerJournals}) =
      _LedgerJournals;
  LedgerJournals._();

  factory LedgerJournals.fromJson(Map<String, dynamic> json) =>
      _$LedgerJournalsFromJson(json);
}

@freezed
abstract class AccountClasses with _$AccountClasses {
  factory AccountClasses({@Default([]) List<AccountClass> accountClasses}) =
      _AccountClasses;
  AccountClasses._();

  factory AccountClasses.fromJson(Map<String, dynamic> json) =>
      _$AccountClassesFromJson(json);
}

@freezed
abstract class AccountTypes with _$AccountTypes {
  factory AccountTypes({@Default([]) List<AccountType> accountTypes}) =
      _AccountTypes;
  AccountTypes._();

  factory AccountTypes.fromJson(Map<String, dynamic> json) =>
      _$AccountTypesFromJson(json);
}

@freezed
abstract class ChatRooms with _$ChatRooms {
  factory ChatRooms({@Default([]) List<ChatRoom> chatRooms}) = _ChatRooms;
  ChatRooms._();

  factory ChatRooms.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomsFromJson(json);
}

@freezed
abstract class ChatMessages with _$ChatMessages {
  factory ChatMessages({@Default([]) List<ChatMessage> chatMessages}) =
      _ChatMessages;
  ChatMessages._();

  factory ChatMessages.fromJson(Map<String, dynamic> json) =>
      _$ChatMessagesFromJson(json);
}

@freezed
abstract class Notifications with _$Notifications {
  factory Notifications({@Default([]) List<NotificationWs> notifications}) =
      _Notifications;
  Notifications._();

  factory Notifications.fromJson(Map<String, dynamic> json) =>
      _$NotificationsFromJson(json);
}

@freezed
abstract class Activities with _$Activities {
  factory Activities({@Default([]) List<Activity> activities}) = _Activities;
  Activities._();

  factory Activities.fromJson(Map<String, dynamic> json) =>
      _$ActivitiesFromJson(json);
}

@freezed
abstract class Opportunities with _$Opportunities {
  factory Opportunities({@Default([]) List<Opportunity> opportunities}) =
      _Opportunities;
  Opportunities._();

  factory Opportunities.fromJson(Map<String, dynamic> json) =>
      _$OpportunitiesFromJson(json);
}

@freezed
abstract class CompaniesUsers with _$CompaniesUsers {
  factory CompaniesUsers({@Default([]) List<CompanyUser> companiesUsers}) =
      _CompaniesUsers;
  CompaniesUsers._();

  factory CompaniesUsers.fromJson(Map<String, dynamic> json) =>
      _$CompaniesUsersFromJson(json);
}

@freezed
abstract class RestRequests with _$RestRequests {
  factory RestRequests({@Default([]) List<RestRequest> restRequests}) =
      _RestRequests;
  RestRequests._();

  factory RestRequests.fromJson(Map<String, dynamic> json) =>
      _$RestRequestsFromJson(json);
}
