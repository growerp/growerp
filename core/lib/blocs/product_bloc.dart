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
  List<Product>? products;

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

  @override
  Stream<ProductState> mapEventToState(ProductEvent event) async* {
    final ProductState currentState = state;
    if (event is FetchProduct) {
      if (currentState is ProductInitial) {
        dynamic result = await repos.getProduct(
            start: 0,
            limit: event.limit,
            assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : null,
            companyPartyId: event.companyPartyId,
            search: event.search);
        if (result is List<Product>) {
          products = result;
          yield ProductSuccess(
              products: result,
              hasReachedMax: result.length < event.limit ? true : false);
        } else
          yield ProductProblem(result);
        return;
      } else if (currentState is ProductSuccess) {
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          yield ProductLoading();
          dynamic result = await repos.getProduct(
              start: 0,
              limit: event.limit,
              assetClassId:
                  classificationId == 'AppHotel' ? 'Hotel Room' : null,
              companyPartyId: event.companyPartyId,
              search: event.search);
          if (result is List<Product>) {
            products = result;
            yield ProductSuccess(
                products: result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield ProductProblem(result);
          return;
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getProduct(
              start: currentState.products!.length,
              limit: event.limit,
              search: event.search,
              companyPartyId: event.companyPartyId);
          if (result is List<Product>) {
            yield currentState.copyWith(
                products: currentState.products! + result,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield ProductProblem(result);
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
            currentState.products?.add(result);
          } else {
            int index = currentState.products!
                .indexWhere((prod) => prod.productId == result.productId);
            currentState.products!.replaceRange(index, index + 1, [result]);
          }
          yield ProductSuccess(
              products: currentState.products,
              hasReachedMax: _hasReachedMax(currentState),
              message: 'product ' + (adding ? 'added' : 'updated'));
        } else {
          yield ProductProblem(result);
        }
      }
    } else if (event is DeleteProduct) {
      if (currentState is ProductSuccess) {
        int index = currentState.products!
            .indexWhere((prod) => prod.productId == event.product.productId);
        String? name = currentState.products![index].productName;
        yield ProductLoading('deleting product $name');
        dynamic result = await repos.deleteProduct(event.product.productId);
        if (result == event.product.productId) {
          currentState.products!.removeAt(index);
          yield ProductSuccess(
                  products: currentState.products,
                  hasReachedMax: _hasReachedMax(currentState))
              .copyWith(message: 'Product $name deleted');
        } else {
          yield ProductProblem(result);
        }
      }
    } else
      print("===Event $event not found");
  }
}

bool _hasReachedMax(ProductState state) =>
    state is ProductSuccess && state.hasReachedMax!;

//#######################events###########################
abstract class ProductEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchProduct extends ProductEvent {
  final String? companyPartyId;
  final String? categoryId;
  final String? assetClassId;
  final int limit;
  final search;
  FetchProduct(
      {this.companyPartyId,
      this.categoryId,
      this.assetClassId,
      this.limit = 20,
      this.search});
  @override
  String toString() => "FetchProduct company: $companyPartyId, "
      "limit: $limit, search: $search";
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
  String toString() => "UpdateProduct: $product";
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
  final List<Product>? products;
  final bool? hasReachedMax;
  final String? message;
  final String? search;

  const ProductSuccess(
      {this.products, this.hasReachedMax, this.message, this.search});

  ProductSuccess copyWith({
    List<Product>? products,
    bool? hasReachedMax,
    String? message,
    String? search,
  }) =>
      ProductSuccess(
        products: products ?? this.products,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        message: message ?? this.message,
        search: search ?? this.search,
      );

  @override
  List<Object?> get props => [products, hasReachedMax];

  @override
  String toString() => 'ProductSuccess { #products: ${products?.length}, '
      'hasReachedMax: $hasReachedMax }';
}
