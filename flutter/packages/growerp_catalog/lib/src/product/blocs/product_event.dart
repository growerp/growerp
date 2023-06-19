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

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object> get props => [];
}

/// Get A product list with optional selection criteria
class ProductFetch extends ProductEvent {
  const ProductFetch(
      {this.categoryId = '',
      this.companyPartyId = '',
      this.searchString = '',
      this.refresh = false});
  final String companyPartyId;
  final String categoryId;
  final String searchString;
  final bool refresh;
  @override
  List<Object> get props => [categoryId, companyPartyId, searchString, refresh];
}

/// delete an existing product
class ProductDelete extends ProductEvent {
  const ProductDelete(this.product);
  final Product product;
}

/// update an existing product
class ProductUpdate extends ProductEvent {
  const ProductUpdate(this.product);
  final Product product;
}

/// initiate a download of products by email.
class ProductDownload extends ProductEvent {}

/// start a [Product] import
class ProductUpload extends ProductEvent {
  const ProductUpload(this.file);
  final String file;
}
