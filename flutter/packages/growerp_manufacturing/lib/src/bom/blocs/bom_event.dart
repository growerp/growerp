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

part of 'bom_bloc.dart';

abstract class BomEvent extends Equatable {
  const BomEvent();
  @override
  List<Object?> get props => [];
}

class BomFetch extends BomEvent {
  const BomFetch({
    this.productId,
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String? productId;
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [productId, searchString, refresh];
}

class BomsFetch extends BomEvent {
  const BomsFetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
  });
  final String searchString;
  final bool refresh;
  final int limit;
  @override
  List<Object?> get props => [searchString, refresh];
}

class BomUpdate extends BomEvent {
  const BomUpdate(this.bomItem);
  final BomItem bomItem;
}

class BomDelete extends BomEvent {
  const BomDelete(this.bomItem);
  final BomItem bomItem;
}
