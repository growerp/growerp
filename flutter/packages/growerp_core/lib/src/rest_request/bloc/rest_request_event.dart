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

part of 'rest_request_bloc.dart';

abstract class RestRequestEvent extends Equatable {
  const RestRequestEvent();

  @override
  List<Object?> get props => [];
}

class RestRequestFetch extends RestRequestEvent {
  const RestRequestFetch({
    this.refresh = false,
    this.limit = 20,
    this.searchString = '',
    this.hitId,
    this.userId,
    this.ownerPartyId,
    this.startDateTime,
    this.endDateTime,
  });

  final bool refresh;
  final int limit;
  final String searchString;
  final String? hitId;
  final String? userId;
  final String? ownerPartyId;
  final String? startDateTime;
  final String? endDateTime;

  @override
  List<Object?> get props => [
    refresh,
    limit,
    searchString,
    hitId,
    userId,
    ownerPartyId,
    startDateTime,
    endDateTime,
  ];
}
