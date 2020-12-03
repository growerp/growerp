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

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:models/models.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final repos;
  Catalog catalog = Catalog(categories: [], products: []);

  CatalogBloc(this.repos) : super(CatalogInitial());
  @override
  Stream<CatalogState> mapEventToState(CatalogEvent event) async* {
    if (event is LoadCatalog) {
      yield CatalogLoading("loading from company: ${event.companyPartyId}");
      String companyPartyId = event.companyPartyId;
      dynamic result = await repos.getCatalog(companyPartyId);
      if (result is Catalog) {
        catalog = result;
        yield CatalogLoaded(catalog: result);
      } else
        yield CatalogProblem(errorMessage: result);
    } else if (event is UpdateProduct) {
      yield CatalogLoading(
          (event.product?.productId == null ? "Adding " : "Updating") +
              " product ${event.product}");
      dynamic result =
          await repos.updateProduct(event.product, event.imagePath);
      if (result is Product) {
        if (event.product?.productId == null) {
          catalog.products?.add(result);
        } else {
          int index = catalog.products
              .indexWhere((prod) => prod.productId == result.productId);
          catalog.products.replaceRange(index, index + 1, [result]);
        }
        yield CatalogLoaded(
            catalog: catalog,
            message: event.product.productId == null
                ? 'Product added'
                : 'Product updated');
      } else {
        yield CatalogProblem(newProduct: event.product, errorMessage: result);
      }
    } else if (event is DeleteProduct) {
      yield CatalogLoading("Deleting product ${event.product.productId}");
      dynamic result = await repos.deleteProduct(event.product.productId);
      if (result == event.product.productId) {
        int index =
            catalog.products.indexWhere((cat) => cat.productId == result);
        catalog.products.removeAt(index);
        yield CatalogLoaded(
            catalog: catalog, message: 'Product ${event.product} deleted');
      }
    } else if (event is UpdateCategory) {
      yield CatalogLoading(
          "${(event.category?.categoryId == null ? 'Adding' : 'Updating')}"
          " category ${event.category}");
      dynamic result =
          await repos.updateCategory(event.category, event.imagePath);
      if (result is ProductCategory) {
        if (event.category?.categoryId == null) {
          catalog.categories.add(result);
        } else {
          int index = catalog.categories
              .indexWhere((cat) => cat.categoryId == result.categoryId);
          catalog.categories.replaceRange(index, index + 1, [result]);
        }
        yield CatalogLoaded(
            catalog: catalog,
            message: event.category.categoryId == null
                ? 'Category added'
                : 'Category updated');
      } else {
        yield CatalogProblem(newCategory: event.category, errorMessage: result);
      }
    } else if (event is DeleteCategory) {
      yield CatalogLoading("Deleting category ${event.category}");
      dynamic result = await repos.deleteCategory(event.category.categoryId);
      if (result == event.category.categoryId) {
        int index =
            catalog.categories.indexWhere((cat) => cat.categoryId == result);
        catalog.categories.removeAt(index);
        yield CatalogLoaded(
            catalog: catalog, message: 'Category ${event.category} deleted');
      }
    }
  }
}

// ################# events ###################
@immutable
abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  @override
  List<Object> get props => [];
}

class LoadCatalog extends CatalogEvent {
  final String companyPartyId;
  LoadCatalog([this.companyPartyId]);
  @override
  String toString() => "Loadcatalog: loading products and categories";
}

class DeleteProduct extends CatalogEvent {
  final Product product;
  DeleteProduct(this.product);
  @override
  String toString() => "DeleteProduct: $product";
}

class UpdateProduct extends CatalogEvent {
  final Product product;
  final String imagePath;
  UpdateProduct(this.product, this.imagePath);
  @override
  String toString() => "UpdateProduct: $product";
}

class DeleteCategory extends CatalogEvent {
  final ProductCategory category;
  DeleteCategory(this.category);
  @override
  String toString() => "DeleteCategory: $category";
}

class UpdateCategory extends CatalogEvent {
  final ProductCategory category;
  final String imagePath;
  UpdateCategory(this.category, this.imagePath);
  @override
  String toString() => "UpdateCategory: $category";
}

// ################## state ###################
@immutable
abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {
  final String message;
  CatalogLoading([this.message]);
  String toString() => 'CatalogLoading msg: $message';
}

class CatalogLoaded extends CatalogState {
  final Catalog catalog;
  final ProductCategory category;
  final Product product;
  final String message;
  const CatalogLoaded(
      {this.catalog, this.category, this.product, this.message});

  @override
  List<Object> get props => [catalog];
  @override
  String toString() => 'CatalogLoaded: catalog: $catalog';
}

class CatalogProblem extends CatalogState {
  final String errorMessage;
  final Product newProduct;
  final ProductCategory newCategory;

  const CatalogProblem({this.errorMessage, this.newProduct, this.newCategory});

  @override
  String toString() => 'CatalogProblem { error: $errorMessage }';
}
