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

enum OpportunityStatus { initial, success, failure }

class OpportunityState extends Equatable {
  const OpportunityState({
    this.status = OpportunityStatus.initial,
    this.opportunities = const <Opportunity>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final OpportunityStatus status;
  final String? message;
  final List<Opportunity> opportunities;
  final bool hasReachedMax;
  final String searchString;

  OpportunityState copyWith({
    OpportunityStatus? status,
    String? message,
    List<Opportunity>? opportunities,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return OpportunityState(
      status: status ?? this.status,
      opportunities: opportunities ?? this.opportunities,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [message, opportunities, hasReachedMax];

  @override
  String toString() => '$status { #opportunities: ${opportunities.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
