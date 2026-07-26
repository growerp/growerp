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

part of 'company_bloc.dart';

enum CompanyStatus { initial, loading, success, failure }

class CompanyState extends Equatable {
  const CompanyState({
    this.status = CompanyStatus.initial,
    this.companies = const <Company>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final CompanyStatus status;
  final String? message;
  final List<Company> companies;
  final bool hasReachedMax;
  final String searchString;

  CompanyState copyWith({
    CompanyStatus? status,
    String? message,
    List<Company>? companies,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return CompanyState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hasReachedMax,
    message,
    companies,
    hasReachedMax,
  ];

  @override
  String toString() =>
      '$status { #companies: ${companies.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
