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

abstract class CashBookCategoryEvent extends Equatable {
  const CashBookCategoryEvent();
  @override
  List<Object?> get props => [];
}

class CashBookCategoryFetch extends CashBookCategoryEvent {
  const CashBookCategoryFetch({this.refresh = false});
  final bool refresh;
  @override
  List<Object?> get props => [refresh];
}

/// switch a category on or off for the cash book, or rename it
class CashBookCategoryUpdate extends CashBookCategoryEvent {
  const CashBookCategoryUpdate(this.category, {this.isUsed, this.accountName});
  final GlAccount category;
  final bool? isUsed;
  final String? accountName;
}

class CashBookCategoryCreate extends CashBookCategoryEvent {
  const CashBookCategoryCreate({
    required this.accountName,
    required this.isIncome,
  });
  final String accountName;
  final bool isIncome;
}
