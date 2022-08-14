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
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/domains/domains.dart';
import 'package:core/services/api_result.dart';
import 'package:core/services/network_exceptions.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as _fast_csv;
import 'package:flutter/foundation.dart' as foundation;
import '../../../api_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

const _productLimit = 20;

EventTransformer<E> productDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(this.repos) : super(const ProductState()) {
    on<ProductFetch>(_onProductFetch,
        transformer: productDroppable(Duration(milliseconds: 100)));
    on<ProductUpdate>(_onProductUpdate);
    on<ProductDelete>(_onProductDelete);
    on<ProductUpload>(_onProductUpload);
    on<ProductDownload>(_onProductDownload);
  }

  final APIRepository repos;

  Future<void> _onProductFetch(
    ProductFetch event,
    Emitter<ProductState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty)
      return;
    try {
      // start from record zero for initial and refresh
      emit(state.copyWith(status: ProductStatus.loading));
      if (state.status == ProductStatus.initial || event.refresh) {
        ApiResult<List<Product>> compResult =
            await repos.getProduct(start: 0, limit: _productLimit);
        return emit(compResult.when(
            success: (data) => state.copyWith(
                  status: ProductStatus.success,
                  products: data,
                  hasReachedMax: data.length < _productLimit ? true : false,
                  searchString: '',
                  message: event.refresh == true ? 'List refreshed...' : null,
                ),
            failure: (NetworkExceptions error) => state.copyWith(
                status: ProductStatus.failure, message: error.toString())));
      }
      // get first search page also for changed search
      if (event.searchString.isNotEmpty && state.searchString.isEmpty ||
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
                status: ProductStatus.failure, message: error.toString())));
      }
      // get next page also for search

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
              status: ProductStatus.failure, message: error.toString())));
    } catch (error) {
      emit(state.copyWith(
          status: ProductStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onProductUpdate(
    ProductUpdate event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.updateLoading));
      List<Product> products = List.from(state.products);
      if (event.product.productId.isNotEmpty) {
        // update
        ApiResult<Product> compResult =
            await repos.updateProduct(event.product);
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
                status: ProductStatus.failure, message: error.toString())));
      } else {
        // add
        ApiResult<Product> compResult =
            await repos.createProduct(event.product);
        return emit(compResult.when(
            success: (data) {
              products.insert(0, data);
              return state.copyWith(
                  status: ProductStatus.success,
                  products: products,
                  message: 'product ${event.product.productName} added');
            },
            failure: (NetworkExceptions error) => state.copyWith(
                status: ProductStatus.failure, message: error.toString())));
      }
    } catch (error) {
      emit(state.copyWith(
          status: ProductStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onProductDelete(
    ProductDelete event,
    Emitter<ProductState> emit,
  ) async {
    try {
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
              status: ProductStatus.failure, message: error.toString())));
    } catch (error) {
      emit(state.copyWith(
          status: ProductStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onProductUpload(
    ProductUpload event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.filesLoading));
      List<Product> products = [];
      final result = _fast_csv.parse(await event.file);
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
          image: Base64Decoder().convert(row[3]),
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
              status: ProductStatus.failure, message: error.toString())));
    } catch (error) {
      emit(state.copyWith(
          status: ProductStatus.failure, message: error.toString()));
    }
  }

  Future<void> _onProductDownload(
    ProductDownload event,
    Emitter<ProductState> emit,
  ) async {
    try {
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
              status: ProductStatus.failure, message: error.toString())));
    } catch (error) {
      emit(state.copyWith(
          status: ProductStatus.failure, message: error.toString()));
    }
  }
}
