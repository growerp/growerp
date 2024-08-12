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
class GlAccounts with _$GlAccounts {
  factory GlAccounts({
    @Default([]) List<GlAccount> glAccounts,
  }) = _GlAccounts;
  GlAccounts._();

  factory GlAccounts.fromJson(Map<String, dynamic> json) =>
      _$GlAccountsFromJson(json);
}

@freezed
class Categories with _$Categories {
  factory Categories({
    @Default([]) List<Category> categories,
  }) = _Categories;
  Categories._();

  factory Categories.fromJson(Map<String, dynamic> json) =>
      _$CategoriesFromJson(json);
}

@freezed
class Products with _$Products {
  factory Products({
    @Default([]) List<Product> products,
  }) = _Products;
  Products._();

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);
}

@freezed
class Assets with _$Assets {
  factory Assets({
    @Default([]) List<Asset> assets,
  }) = _Assets;
  Assets._();

  factory Assets.fromJson(Map<String, dynamic> json) => _$AssetsFromJson(json);
}

@freezed
class Users with _$Users {
  factory Users({
    @Default([]) List<User> users,
  }) = _Users;
  Users._();

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);
}

@freezed
class Companies with _$Companies {
  factory Companies({
    @Default([]) List<Company> companies,
  }) = _Companies;
  Companies._();

  factory Companies.fromJson(Map<String, dynamic> json) =>
      _$CompaniesFromJson(json);
}

@freezed
class RentalFullDates with _$RentalFullDates {
  factory RentalFullDates({
    @Default([]) List<String> rentalFullDates,
  }) = _RentalFullDates;
  RentalFullDates._();

  factory RentalFullDates.fromJson(Map<String, dynamic> json) =>
      _$RentalFullDatesFromJson(json);
}

@freezed
class FinDocs with _$FinDocs {
  factory FinDocs({
    @Default([]) List<FinDoc> finDocs,
  }) = _FinDocs;
  FinDocs._();

  factory FinDocs.fromJson(Map<String, dynamic> json) =>
      _$FinDocsFromJson(json);
}

@freezed
class FinDocItems with _$FinDocItems {
  factory FinDocItems({
    @Default([]) List<FinDocItem> finDocItems,
  }) = _FinDocItems;
  FinDocItems._();

  factory FinDocItems.fromJson(Map<String, dynamic> json) =>
      _$FinDocItemsFromJson(json);
}

@freezed
class ItemTypes with _$ItemTypes {
  factory ItemTypes({
    @Default([]) List<ItemType> itemTypes,
  }) = _ItemTypes;
  ItemTypes._();

  factory ItemTypes.fromJson(Map<String, dynamic> json) =>
      _$ItemTypesFromJson(json);
}

@freezed
class PaymentTypes with _$PaymentTypes {
  factory PaymentTypes({
    @Default([]) List<PaymentType> paymentTypes,
  }) = _PaymentTypes;
  PaymentTypes._();

  factory PaymentTypes.fromJson(Map<String, dynamic> json) =>
      _$PaymentTypesFromJson(json);
}

@freezed
class Locations with _$Locations {
  factory Locations({
    @Default([]) List<Location> locations,
  }) = _Locations;
  Locations._();

  factory Locations.fromJson(Map<String, dynamic> json) =>
      _$LocationsFromJson(json);
}

@freezed
class TimePeriods with _$TimePeriods {
  factory TimePeriods({
    @Default([]) List<TimePeriod> timePeriods,
  }) = _TimePeriods;
  TimePeriods._();

  factory TimePeriods.fromJson(Map<String, dynamic> json) =>
      _$TimePeriodsFromJson(json);
}

@freezed
class LedgerJournals with _$LedgerJournals {
  factory LedgerJournals({
    @Default([]) List<LedgerJournal> ledgerJournals,
  }) = _LedgerJournals;
  LedgerJournals._();

  factory LedgerJournals.fromJson(Map<String, dynamic> json) =>
      _$LedgerJournalsFromJson(json);
}

@freezed
class AccountClasses with _$AccountClasses {
  factory AccountClasses({
    @Default([]) List<AccountClass> accountClasses,
  }) = _AccountClasses;
  AccountClasses._();

  factory AccountClasses.fromJson(Map<String, dynamic> json) =>
      _$AccountClassesFromJson(json);
}

@freezed
class AccountTypes with _$AccountTypes {
  factory AccountTypes({
    @Default([]) List<AccountType> accountTypes,
  }) = _AccountTypes;
  AccountTypes._();

  factory AccountTypes.fromJson(Map<String, dynamic> json) =>
      _$AccountTypesFromJson(json);
}

@freezed
class ChatRooms with _$ChatRooms {
  factory ChatRooms({
    @Default([]) List<ChatRoom> chatRooms,
  }) = _ChatRooms;
  ChatRooms._();

  factory ChatRooms.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomsFromJson(json);
}

@freezed
class ChatMessages with _$ChatMessages {
  factory ChatMessages({
    @Default([]) List<ChatMessage> chatMessages,
  }) = _ChatMessages;
  ChatMessages._();

  factory ChatMessages.fromJson(Map<String, dynamic> json) =>
      _$ChatMessagesFromJson(json);
}

@freezed
class Tasks with _$Tasks {
  factory Tasks({
    @Default([]) List<Task> tasks,
  }) = _Tasks;
  Tasks._();

  factory Tasks.fromJson(Map<String, dynamic> json) => _$TasksFromJson(json);
}

@freezed
class Opportunities with _$Opportunities {
  factory Opportunities({
    @Default([]) List<Opportunity> opportunities,
  }) = _Opportunities;
  Opportunities._();

  factory Opportunities.fromJson(Map<String, dynamic> json) =>
      _$OpportunitiesFromJson(json);
}

@freezed
class CompaniesUsers with _$CompaniesUsers {
  factory CompaniesUsers({
    @Default([]) List<CompanyUser> companiesUsers,
  }) = _CompaniesUsers;
  CompaniesUsers._();

  factory CompaniesUsers.fromJson(Map<String, dynamic> json) =>
      _$CompaniesUsersFromJson(json);
}
