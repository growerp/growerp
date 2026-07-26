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
