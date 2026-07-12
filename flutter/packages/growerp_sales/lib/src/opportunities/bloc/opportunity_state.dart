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
