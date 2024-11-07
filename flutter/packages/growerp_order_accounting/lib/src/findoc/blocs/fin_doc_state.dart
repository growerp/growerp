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

part of 'fin_doc_bloc.dart';

enum FinDocStatus {
  initial,
  loading,
  parmLoading,
  success,
  parmSuccess,
  failure
}

class FinDocState extends Equatable {
  const FinDocState({
    this.status = FinDocStatus.initial,
    this.finDocs = const [],
    this.finDocItems = const [],
    this.itemTypes =
        const [], // item types for invoice paymentType for payments
    this.paymentTypes = const [],
    this.users = const [],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.productFullDates = const <Product>[],
  });

  final FinDocStatus status;
  final String? message;
  final List<FinDoc> finDocs;
  final List<FinDocItem> finDocItems;
  final List<ItemType> itemTypes;
  final List<PaymentType> paymentTypes;
  final List<User> users;
  final bool hasReachedMax;
  final String searchString;
  final List<Product> productFullDates;

  FinDocState copyWith({
    FinDocStatus? status,
    String? message,
    List<FinDoc>? finDocs,
    List<FinDocItem>? finDocItems,
    List<ItemType>? itemTypes,
    List<PaymentType>? paymentTypes,
    List<User>? users,
    bool? hasReachedMax,
    String? searchString,
    List<String>? occupancyDates,
    List<Product>? productFullDates,
  }) {
    return FinDocState(
      status: status ?? this.status,
      finDocs: finDocs ?? this.finDocs,
      finDocItems: finDocItems ?? this.finDocItems,
      itemTypes: itemTypes ?? this.itemTypes,
      paymentTypes: paymentTypes ?? this.paymentTypes,
      users: users ?? this.users,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      productFullDates: productFullDates ?? this.productFullDates,
    );
  }

  @override
  List<Object?> get props => [status, message, finDocs];

  @override
  String toString() => '$status { #finDocs: ${finDocs.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
