/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of 'fin_doc_bloc.dart';

enum FinDocStatus { initial, loading, success, failure }

class FinDocState extends Equatable {
  const FinDocState({
    this.status = FinDocStatus.initial,
    this.finDocs = const [],
    this.finDoc,
    this.finDocItems = const [],
    this.itemTypes =
        const [], // item types for invoice paymentType for payments
    this.paymentTypes = const [],
    this.users = const [],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.productRentalDates = const <ProductRentalDate>[],
  });

  final FinDocStatus status;
  final String? message;
  final List<FinDoc> finDocs;
  final FinDoc? finDoc;
  final List<FinDocItem> finDocItems;
  final List<ItemType> itemTypes;
  final List<PaymentType> paymentTypes;
  final List<User> users;
  final bool hasReachedMax;
  final String searchString;
  final List<ProductRentalDate>
  productRentalDates; // productId and rental dates

  FinDocState copyWith({
    FinDocStatus? status,
    String? message,
    List<FinDoc>? finDocs,
    FinDoc? finDoc,
    List<FinDocItem>? finDocItems,
    List<ItemType>? itemTypes,
    List<PaymentType>? paymentTypes,
    List<User>? users,
    bool? hasReachedMax,
    String? searchString,
    List<ProductRentalDate>? productRentalDates,
  }) {
    return FinDocState(
      status: status ?? this.status,
      finDocs: finDocs ?? this.finDocs,
      finDoc: finDoc ?? this.finDoc,
      finDocItems: finDocItems ?? this.finDocItems,
      itemTypes: itemTypes ?? this.itemTypes,
      paymentTypes: paymentTypes ?? this.paymentTypes,
      users: users ?? this.users,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      productRentalDates: productRentalDates ?? this.productRentalDates,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    finDocs,
    productRentalDates,
    finDoc,
  ];

  @override
  String toString() =>
      '$status { #finDocs: ${finDocs.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
