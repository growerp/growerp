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

part of 'party_bloc.dart';

enum PartyStatus { initial, loading, success, failure }

class PartyState extends Equatable {
  const PartyState({
    this.status = PartyStatus.initial,
    this.parties = const <Party>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final PartyStatus status;
  final String? message;
  final List<Party> parties;
  final bool hasReachedMax;
  final String searchString;

  PartyState copyWith({
    PartyStatus? status,
    String? message,
    List<Party>? parties,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return PartyState(
      status: status ?? this.status,
      parties: parties ?? this.parties,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [status, message, parties, hasReachedMax];

  @override
  String toString() => '$status { #parties: ${parties.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
