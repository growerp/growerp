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

part of 'cash_book_category_bloc.dart';

enum CashBookCategoryStatus { initial, loading, success, failure }

class CashBookCategoryState extends Equatable {
  const CashBookCategoryState({
    this.status = CashBookCategoryStatus.initial,
    this.incomeCategories = const <GlAccount>[],
    this.expenseCategories = const <GlAccount>[],
    this.message,
  });

  final CashBookCategoryStatus status;
  final List<GlAccount> incomeCategories;
  final List<GlAccount> expenseCategories;
  final String? message;

  CashBookCategoryState copyWith({
    CashBookCategoryStatus? status,
    List<GlAccount>? incomeCategories,
    List<GlAccount>? expenseCategories,
    String? message,
  }) {
    return CashBookCategoryState(
      status: status ?? this.status,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    incomeCategories,
    expenseCategories,
  ];

  @override
  String toString() =>
      '$status { #income: ${incomeCategories.length}, '
      '#expense: ${expenseCategories.length}, message: $message }';
}
