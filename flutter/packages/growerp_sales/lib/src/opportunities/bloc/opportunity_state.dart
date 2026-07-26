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

part of 'opportunity_bloc.dart';

// summarySuccess is separate from success so views listening for success
// (e.g. the dialog pop) do not react to a background summary refresh
enum OpportunityStatus { initial, loading, success, summarySuccess, failure }

class OpportunityState extends Equatable {
  const OpportunityState({
    this.status = OpportunityStatus.initial,
    this.opportunities = const <Opportunity>[],
    this.searchResults = const <Opportunity>[],
    this.summary = const <OpportunitySummaryItem>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.convertedOrderId,
    this.convertedPseudoId,
  });

  final OpportunityStatus status;
  final String? message;
  final List<Opportunity> opportunities;
  final List<Opportunity> searchResults;
  final List<OpportunitySummaryItem> summary;
  final bool hasReachedMax;
  final String searchString;
  final String? convertedOrderId;
  final String? convertedPseudoId;

  OpportunityState copyWith({
    OpportunityStatus? status,
    String? message,
    List<Opportunity>? opportunities,
    List<Opportunity>? searchResults,
    List<OpportunitySummaryItem>? summary,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
    String? convertedOrderId,
    String? convertedPseudoId,
  }) {
    return OpportunityState(
      status: status ?? this.status,
      opportunities: opportunities ?? this.opportunities,
      searchResults: searchResults ?? this.searchResults,
      summary: summary ?? this.summary,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      convertedOrderId: convertedOrderId,
      convertedPseudoId: convertedPseudoId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    opportunities,
    searchResults,
    summary,
    hasReachedMax,
    convertedOrderId,
    convertedPseudoId,
  ];

  @override
  String toString() =>
      '$status { #opportunities: ${opportunities.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
