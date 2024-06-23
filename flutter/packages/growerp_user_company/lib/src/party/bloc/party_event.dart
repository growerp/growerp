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

abstract class PartyEvent extends Equatable {
  const PartyEvent();
  @override
  List<Object> get props => [];
}

class PartyFetch extends PartyEvent {
  final UserGroup? partyGroup;
  final String searchString;
  final bool refresh;
  final int limit;

  const PartyFetch(
      {this.limit = 20,
      this.partyGroup,
      this.searchString = '',
      this.refresh = false});

  @override
  List<Object> get props => [searchString, refresh];
}

class PartyUpdate extends PartyEvent {
  final Party party;
  const PartyUpdate(this.party);
}

class PartyDelete extends PartyEvent {
  final Party party;
  const PartyDelete(this.party);
}
