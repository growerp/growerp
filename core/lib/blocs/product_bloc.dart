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
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';
import 'package:global_configuration/global_configuration.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final repos;
  List<Product> products = [];

  ProductBloc(
    this.repos,
  ) : super(ProductInitial());

  String classificationId =
      GlobalConfiguration().getValue<String>("classificationId");

  @override
  Stream<Transition<ProductEvent, ProductState>> transformEvents(
    Stream<ProductEvent> events,
    TransitionFunction<ProductEvent, ProductState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  Stream<ProductState> getProducts(
      {required dynamic event,
      List<Product> products = const <Product>[],
      int start = 0,
      String? searchString}) async* {
    dynamic result = await repos.getProduct(
        start: start,
        limit: event.limit,
        assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : null,
        companyPartyId: event.companyPartyId,
        search: searchString);
    if (result is List<Product>) {
      yield ProductSuccess(
          products: products + result,
          searchString: searchString,
          hasReachedMax: result.length < event.limit ? true : false);
    } else
      yield ProductProblem(result);
  }

  @override
  Stream<ProductState> mapEventToState(ProductEvent event) async* {
    final ProductState currentState = state;
    if (event is FetchProduct) {
      // refresh or initial
      if (event.refresh || currentState is ProductInitial) {
        yield* getProducts(
            event: event,
            searchString: currentState is ProductSuccess
                ? currentState.searchString
                : null);
      } else if (currentState is ProductSuccess) {
        // if we need to search
        if (event.search != null && currentState.searchString == null ||
            (currentState.searchString != null &&
                event.search != currentState.searchString)) {
          yield* getProducts(
              event: event,
              products: currentState.products,
              searchString: event.search);
        } else if (!_hasReachedMax(currentState)) {
          // get next page
          yield* getProducts(
              event: event,
              products: currentState.products,
              start: currentState.products.length);
        }
      }
    } else if (event is UpdateProduct) {
      bool adding = event.product.productId == null;
      yield ProductLoading((adding ? 'adding' : 'updating') +
          ' product ${event.product.productName}');
      dynamic result = await repos.updateProduct(event.product);
      if (currentState is ProductSuccess) {
        if (result is Product) {
          if (adding) {
            currentState.products.add(result);
          } else {
            int index = currentState.products
                .indexWhere((prod) => prod.productId == result.productId);
            currentState.products[index] = result;
          }
          yield currentState.copyWith(
              message: 'product ' + (adding ? 'added' : 'updated'));
        } else {
          yield ProductProblem(result);
        }
      }
    } else if (event is DeleteProduct) {
      if (currentState is ProductSuccess) {
        int index = currentState.products
            .indexWhere((prod) => prod.productId == event.product.productId);
        String? name = currentState.products[index].productName;
        yield ProductLoading('deleting product $name');
        dynamic result = await repos.deleteProduct(event.product.productId);
        if (result == event.product.productId) {
          currentState.products.removeAt(index);
          yield currentState.copyWith(message: 'Product $name deleted');
        } else {
          yield ProductProblem(result);
        }
      }
    } else
      print("===Event $event not found");
  }
}

bool _hasReachedMax(ProductState state) =>
    state is ProductSuccess && state.hasReachedMax;

//#######################events###########################
abstract class ProductEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchProduct extends ProductEvent {
  final bool refresh;
  final String? companyPartyId;
  final String? categoryId;
  final String? assetClassId;
  final int limit;
  final search;
  FetchProduct(
      {this.refresh = false,
      this.companyPartyId,
      this.categoryId,
      this.assetClassId,
      this.limit = 20,
      this.search});
  @override
  String toString() => "FetchProduct company: $companyPartyId, "
      "refresh: $refresh limit: $limit, search: $search";
}

class DeleteProduct extends ProductEvent {
  final Product product;
  DeleteProduct(this.product);
  @override
  String toString() => "DeleteProduct: $product";
}

class UpdateProduct extends ProductEvent {
  final Product product;
  UpdateProduct(this.product);
  @override
  String toString() =>
      "${product.productId == null ? 'Add' : 'Update'}Product: $product";
}

//#######################state############################
abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {
  final String? message;
  ProductLoading([this.message]);
  @override
  List<Object?> get props => [message];
  @override
  String toString() => 'Product loading...';
}

class ProductProblem extends ProductState {
  final String? errorMessage;
  ProductProblem(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
  @override
  String toString() => 'ProductProblem { errorMessage $errorMessage }';
}

class ProductSuccess extends ProductState {
  final List<Product> products;
  final bool hasReachedMax;
  final String? message;
  final String? searchString;

  const ProductSuccess(
      {required this.products,
      required this.hasReachedMax,
      this.message,
      this.searchString});

  ProductSuccess copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    String? message,
    String? searchString,
  }) =>
      ProductSuccess(
        products: products ?? this.products,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        message: message ?? this.message,
        searchString: searchString ?? this.searchString,
      );

  @override
  List<Object?> get props => [products, hasReachedMax, message, searchString];

  @override
  String toString() => 'ProductSuccess { #products: ${products.length}, '
      'hasReachedMax: $hasReachedMax }';
}
