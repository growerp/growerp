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

part of 'product_bloc.dart';

enum ProductStatus {
  initial,
  loading,
  filesLoading,
  updateLoading,
  success,
  failure
}

class ProductState extends Equatable {
  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const <Product>[],
    this.message,
    this.hasReachedMax = false,
    this.searchString = '',
  });

  final ProductStatus status;
  final String? message;
  final List<Product> products;
  final bool hasReachedMax;
  final String searchString;

  ProductState copyWith({
    ProductStatus? status,
    String? message,
    List<Product>? products,
    bool error = false,
    bool? hasReachedMax,
    String? searchString,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchString: searchString ?? this.searchString,
    );
  }

  @override
  List<Object?> get props => [message, products, hasReachedMax];

  @override
  String toString() => '$status { #products: ${products.length}, '
      'hasReachedMax: $hasReachedMax message $message}';
}
