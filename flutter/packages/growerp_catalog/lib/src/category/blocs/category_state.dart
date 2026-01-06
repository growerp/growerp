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

part of 'category_bloc.dart';

enum CategoryStatus { initial, loading, success, failure }

class CategoryState extends Equatable {
  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const <Category>[],
    this.companyPartyId = '',
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final CategoryStatus status;
  final String? message;
  final List<Category> categories;
  final String? companyPartyId;
  final bool hasReachedMax;
  final String searchString;

  CategoryState copyWith({
    CategoryStatus? status,
    String? message,
    List<Category>? categories,
    String? companyPartyId,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      companyPartyId: companyPartyId ?? this.companyPartyId,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    categories,
    companyPartyId,
    hasReachedMax,
  ];

  @override
  String toString() =>
      '$status { #categories: ${categories.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
