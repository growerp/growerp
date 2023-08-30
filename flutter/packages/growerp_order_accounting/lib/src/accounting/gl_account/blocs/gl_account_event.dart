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

part of 'gl_account_bloc.dart';

abstract class GlAccountEvent extends Equatable {
  const GlAccountEvent();
  @override
  List<Object> get props => [];
}

class GlAccountFetch extends GlAccountEvent {
  const GlAccountFetch({this.searchString = '', this.refresh = false});
  final String searchString;
  final bool refresh;
  @override
  List<Object> get props => [searchString, refresh];
}

class GlAccountUpdate extends GlAccountEvent {
  const GlAccountUpdate(this.glAccount);
  final GlAccount glAccount;
}

class GlAccountDelete extends GlAccountEvent {
  const GlAccountDelete(this.glAccount);
  final GlAccount glAccount;
}

class GlAccountClassesFetch extends GlAccountEvent {
  const GlAccountClassesFetch();
}
