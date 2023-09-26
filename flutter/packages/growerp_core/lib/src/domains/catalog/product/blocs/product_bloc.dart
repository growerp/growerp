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
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_rest/growerp_rest.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'product_event.dart';
part 'product_state.dart';

const _productLimit = 20;

EventTransformer<E> productDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Bloc to access [Product] information
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(this.repos) : super(const ProductState()) {
    on<ProductFetch>(_onProductFetch,
        transformer: productDroppable(const Duration(milliseconds: 100)));
    on<ProductUpdate>(_onProductUpdate);
    on<ProductDelete>(_onProductDelete);
    on<ProductUpload>(_onProductUpload);
    on<ProductDownload>(_onProductDownload);
    on<ProductRentalOccupancy>(_onProductRentalOccupancy);
  }

  final CatalogAPIRepository repos;

  Future<void> _onProductFetch(
    ProductFetch event,
    Emitter<ProductState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    emit(state.copyWith(status: ProductStatus.loading));
    // start from record zero for initial and refresh
    if (state.status == ProductStatus.initial || event.refresh) {
      ApiResult<List<Product>> compResult = await repos.getProduct(
        start: 0,
        limit: _productLimit,
        assetClassId: event.assetClassId,
        searchString: event.searchString,
      );
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: ProductStatus.success,
                products: data,
                hasReachedMax: data.length < _productLimit ? true : false,
                searchString: '',
                message: event.refresh == true ? 'List refreshed...' : null,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ProductStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get first search page also for changed search
    else if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
        (state.searchString.isNotEmpty &&
            event.searchString != state.searchString)) {
      ApiResult<List<Product>> compResult = await repos.getProduct(
          searchString: event.searchString, start: 0, limit: _productLimit);
      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: ProductStatus.success,
                products: data,
                hasReachedMax: data.length < _productLimit ? true : false,
                searchString: event.searchString,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ProductStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    // get next page also for search
    else {
      ApiResult<List<Product>> compResult = await repos.getProduct(
          searchString: event.searchString,
          start: state.products.length,
          limit: _productLimit);

      return emit(compResult.when(
          success: (data) => state.copyWith(
                status: ProductStatus.success,
                products: List.of(state.products)..addAll(data),
                hasReachedMax: data.length < _productLimit ? true : false,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ProductStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onProductUpdate(
    ProductUpdate event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.updateLoading));
    List<Product> products = List.from(state.products);
    if (event.product.productId.isNotEmpty) {
      // update
      ApiResult<Product> compResult = await repos.updateProduct(event.product);
      return emit(compResult.when(
          success: (data) {
            int index = products.indexWhere(
                (element) => element.productId == event.product.productId);
            products[index] = data;
            return state.copyWith(
                status: ProductStatus.success,
                products: products,
                message: 'product ${event.product.productName} updated');
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: ProductStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    } else {
      // add
      ApiResult<Product> compResult = await repos.createProduct(event.product);
      return emit(compResult.when(
          success: (data) {
            products.insert(0, data);
            return state.copyWith(
                status: ProductStatus.success,
                products: products,
                message: 'product ${event.product.productName} added');
          },
          failure: (NetworkExceptions error) => state.copyWith(
              status: ProductStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
  }

  Future<void> _onProductDelete(
    ProductDelete event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));
    List<Product> products = List.from(state.products);
    ApiResult<Product> compResult = await repos.deleteProduct(event.product);
    return emit(compResult.when(
        success: (data) {
          int index = products.indexWhere(
              (element) => element.productId == event.product.productId);
          products.removeAt(index);
          return state.copyWith(
              status: ProductStatus.success,
              products: products,
              message: 'product ${event.product.productName} deleted');
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: ProductStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onProductUpload(
    ProductUpload event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.filesLoading));
    List<Product> products = [];
    final result = fast_csv.parse(event.file);
    int line = 0;
    // import csv into products
    for (final row in result) {
      if (line++ < 2 || row.length < 12) continue;
      List<Category> categories = [];
      if (row[9].isNotEmpty) categories.add(Category(categoryName: row[9]));
      if (row[10].isNotEmpty) categories.add(Category(categoryName: row[10]));
      if (row[11].isNotEmpty) categories.add(Category(categoryName: row[11]));

      products.add(Product(
        productName: row[0],
        description: row[1],
        productTypeId: row[2],
        image: const Base64Decoder().convert(row[3]),
        assetClassId: row[4],
        listPrice: Decimal.parse(row[5]),
        price: Decimal.parse(row[6]),
        useWarehouse: row[7] == 'true' ? true : false,
        assetCount: int.parse(row[8]),
        categories: categories,
      ));
    }

    ApiResult<String> compResult = await repos.importProducts(products);
    return emit(compResult.when(
        success: (data) {
          return state.copyWith(
              status: ProductStatus.success,
              products: state.products,
              message: data);
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: ProductStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onProductDownload(
    ProductDownload event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.filesLoading));
    ApiResult<String> compResult = await repos.exportProducts();
    return emit(compResult.when(
        success: (data) {
          return state.copyWith(
              status: ProductStatus.success,
              products: state.products,
              message:
                  "The request is scheduled and the email will be sent shortly");
        },
        failure: (NetworkExceptions error) => state.copyWith(
            status: ProductStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }

  Future<void> _onProductRentalOccupancy(
    ProductRentalOccupancy event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading));
    if (event.productId.isNotEmpty) {
      ApiResult<List<String>> result =
          await repos.getRentalOccupancy(productId: event.productId);
      return emit(result.when(
          success: (data) => state.copyWith(
                status: ProductStatus.success,
                occupancyDates: data,
              ),
          failure: (NetworkExceptions error) => state.copyWith(
              status: ProductStatus.failure,
              message: NetworkExceptions.getErrorMessage(error))));
    }
    ApiResult<List<FullDatesProductRental>> result =
        await repos.getRentalAllOccupancy();
    return emit(result.when(
        success: (data) => state.copyWith(
              status: ProductStatus.success,
              fullDates: data,
            ),
        failure: (NetworkExceptions error) => state.copyWith(
            status: ProductStatus.failure,
            message: NetworkExceptions.getErrorMessage(error))));
  }
}
