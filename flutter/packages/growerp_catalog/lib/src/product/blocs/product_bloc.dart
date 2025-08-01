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
    on<ProductUom>(_onProductUom);
  }

  final RestClient restClient;
  final String classificationId;
  int start = 0;

  Future<void> _onProductFetch(
    ProductFetch event,
    Emitter<ProductState> emit,
  ) async {
    List<Product> current = [];
    if (state.status == ProductStatus.initial ||
        event.refresh ||
        event.searchString.isNotEmpty) {
      start = 0;
      current = [];
      add(const ProductUom([
        'UT_WEIGHT_MEASURE',
        'UT_VOLUME_DRY_MEAS',
        'UT_VOLUME_LIQ_MEAS',
        'UT_TIME_FREQ_MEASURE',
        'UT_LENGTH_MEASURE',
        'UT_OTHER_MEASURE',
      ]));
    } else {
      start = state.products.length;
      current = List.of(state.products);
    }
    try {
      Products compResult = await restClient.getProduct(
          searchString: event.searchString,
          isForDropDown: event.isForDropDown,
          assetClassId: event.assetClassId,
          start: start,
          limit: event.limit,
          classificationId: classificationId);
      emit(state.copyWith(
        status: ProductStatus.success,
        products: current..addAll(compResult.products),
        hasReachedMax: compResult.products.length < event.limit,
        searchString: event.searchString,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: await getDioError(e)));
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
          message: await getDioError(e)));
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
          message: await getDioError(e)));
    }
  }

  Future<void> _onProductUpload(
    ProductUpload event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.loading));
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
          listPrice: Decimal.tryParse(row[5]),
          price: Decimal.tryParse(row[6]),
          useWarehouse: row[7] == 'true' ? true : false,
          assetCount: row[8] != '' ? int.parse(row[8]) : 0,
          categories: categories,
        ));
      }

      await restClient.importProducts(products, classificationId);
      emit(state.copyWith(
          status: ProductStatus.success,
          products: state.products,
          message: 'Products imported.'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure, message: await getDioError(e)));
    }
  }

  Future<void> _onProductDownload(
    ProductDownload event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.loading));
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
          message: await getDioError(e)));
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
          occupancyDates:
              result.products.isNotEmpty ? result.products[0].fullDates : [],
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
          message: await getDioError(e)));
    }
  }

  Future<void> _onProductUom(
    ProductUom event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductStatus.loading));
      Uoms uoms = await restClient.getUom(event.uomTypes);
      List<Uom> uomList = uoms.uoms;
      emit(state.copyWith(status: ProductStatus.success, uoms: uomList));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: ProductStatus.failure,
          products: [],
          message: await getDioError(e)));
    }
  }
}
