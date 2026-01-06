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
  const ProductFetch({
    this.categoryId = '',
    this.assetClassId = '',
    this.companyPartyId = '',
    this.searchString = '', // general search
    this.isForDropDown = false, // for dropdowns
    this.refresh = false,
    this.limit = 20,
  });
  final String companyPartyId;
  final String categoryId;
  final String assetClassId;
  final String searchString;
  final bool isForDropDown;
  final bool refresh;
  final int limit;
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

/// get the rental  usage of related assets for rental purposes
class ProductRentalOccupancy extends ProductEvent {
  const ProductRentalOccupancy({this.productId = ""});
  final String productId;
}

/// initiate a download of products by email.
class ProductDownload extends ProductEvent {}

/// start a [Product] import
class ProductUpload extends ProductEvent {
  const ProductUpload(this.file);
  final String file;
}

/// start a [Product] import
class ProductUom extends ProductEvent {
  const ProductUom(this.uomTypes);
  final List<String>? uomTypes;
}
