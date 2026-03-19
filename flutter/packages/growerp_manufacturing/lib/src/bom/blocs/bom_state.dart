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

enum BomStatus { initial, loading, success, failure }

class BomState extends Equatable {
  const BomState({
    this.status = BomStatus.initial,
    this.boms = const <Bom>[],
    this.bomItems = const <BomItem>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
    this.productId,
  });

  final BomStatus status;
  final String? message;
  final List<Bom> boms;
  final List<BomItem> bomItems;
  final bool hasReachedMax;
  final String searchString;
  final String? productId;

  BomState copyWith({
    BomStatus? status,
    String? message,
    List<Bom>? boms,
    List<BomItem>? bomItems,
    bool? hasReachedMax,
    String? searchString,
    String? productId,
  }) {
    return BomState(
      status: status ?? this.status,
      boms: boms ?? this.boms,
      bomItems: bomItems ?? this.bomItems,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
      productId: productId ?? this.productId,
    );
  }

  @override
  List<Object?> get props => [boms, bomItems, hasReachedMax, status, productId];

  @override
  String toString() =>
      '$status { #boms: ${boms.length}, #bomItems: ${bomItems.length}, '
      'hasReachedMax: $hasReachedMax, message: $message }';
}
