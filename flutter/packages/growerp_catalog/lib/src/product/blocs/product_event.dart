/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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

class ProductSearchChanged extends ProductEvent {
  const ProductSearchChanged({
    required this.searchString,
    this.categoryId = '',
    this.assetClassId = '',
    this.companyPartyId = '',
    this.limit = 20,
  });
  final String searchString;
  final String categoryId;
  final String assetClassId;
  final String companyPartyId;
  final int limit;
}
