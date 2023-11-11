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
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'product_event.dart';
part 'product_state.dart';

EventTransformer<E> productDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// Bloc to access [Product] information
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(
    this.restClient,
    this.classificationId,
  ) : super(const ProductState()) {
    on<ProductFetch>(_onProductFetch,
        transformer: productDroppable(const Duration(milliseconds: 100)));
    on<ProductUpdate>(_onProductUpdate);
    on<ProductDelete>(_onProductDelete);
    on<ProductUpload>(_onProductUpload);
    on<ProductDownload>(_onProductDownload);
    on<ProductRentalOccupancy>(_onProductRentalOccupancy);
  }

  final RestClient restClient;
  final String classificationId;
  int start = 0;

  Future<void> _onProductFetch(
    ProductFetch event,
    Emitter<ProductState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString.isEmpty) {
      return;
    }
    try {
      emit(state.copyWith(status: ProductStatus.loading));

      if (state.status == ProductStatus.initial ||
          event.refresh ||
          event.searchString != '') {
        start = 0;
      } else {
        start = state.products.length;
      }
      Products compResult = await restClient.getProduct(
          searchString: event.searchString,
          assetClassId: event.assetClassId,
          start: start,
          limit: event.limit,
          classificationId: classificationId);
      emit(state.copyWith(
        status: ProductStatus.success,
        products: start == 0
            ? compResult.products
            : (List.of(state.products)..addAll(compResult.products)),
        hasReachedMax: compResult.products.length < event.limit ? true : false,
        searchString: event.searchString,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onProductUpdate(
    ProductUpdate event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.loading));
      List<Product> products = List.from(state.products);
      if (event.product.productId.isNotEmpty) {
        // update
        Product compResult = await restClient.updateProduct(
            product: event.product, classificationId: classificationId);
        int index = products.indexWhere(
            (element) => element.productId == event.product.productId);
        products[index] = compResult;
        emit(state.copyWith(
            status: ProductStatus.success,
            products: products,
            message: "Product ${event.product.productName} updated"));
      } else {
        // add
        Product compResult = await restClient.createProduct(
            product: event.product, classificationId: classificationId);
        products.insert(0, compResult);
        emit(state.copyWith(
            status: ProductStatus.success,
            products: products,
            message: "Product ${event.product.productName} added"));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onProductDelete(
    ProductDelete event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.loading));
      List<Product> products = List.from(state.products);
      await restClient.deleteProduct(product: event.product);
      int index = products.indexWhere(
          (element) => element.productId == event.product.productId);
      products.removeAt(index);
      emit(state.copyWith(
          status: ProductStatus.success,
          products: products,
          message: 'product ${event.product.productName} deleted'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onProductUpload(
    ProductUpload event,
    Emitter<ProductState> emit,
  ) async {
    try {
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

      String compResult = await restClient.importScreenProducts(
          products: products, classificationId: classificationId);
      emit(state.copyWith(
          status: ProductStatus.success,
          products: state.products,
          message: compResult));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onProductDownload(
    ProductDownload event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.filesLoading));
      await restClient.exportScreenProducts(classificationId: classificationId);
      emit(state.copyWith(
          status: ProductStatus.success,
          products: state.products,
          message:
              "The request is scheduled and the email will be sent shortly"));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onProductRentalOccupancy(
    ProductRentalOccupancy event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.loading));
      if (event.productId.isNotEmpty) {
        Products result = await restClient.getDailyRentalOccupancy(
            productId: event.productId);
        emit(state.copyWith(
          status: ProductStatus.success,
          occupancyDates: result.products[0].fullDates,
        ));
      } else {
        Products result = await restClient.getDailyRentalOccupancy();
        emit(state.copyWith(
          status: ProductStatus.success,
          productFullDates: result.products,
        ));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: getDioError(e)));
    }
  }
}
