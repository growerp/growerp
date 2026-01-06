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

part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object> get props => [];
}

class UserFetch extends UserEvent {
  final UserGroup? userGroup;
  final String? partyId;
  final String searchString;
  final bool refresh;
  final int limit;

  const UserFetch({
    this.limit = 20,
    this.partyId,
    this.userGroup,
    this.searchString = '',
    this.refresh = false,
  });

  @override
  List<Object> get props => [searchString, refresh];
}

class UserUpdate extends UserEvent {
  final User user;
  const UserUpdate(this.user);
}

class UserDelete extends UserEvent {
  final User user;
  const UserDelete(this.user);
}
