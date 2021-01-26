import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final repos;
  List<Product> products;

  ProductBloc(
    this.repos,
  ) : super(ProductInitial());

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
    final currentState = state;
    if (event is FetchProduct && !_hasReachedMax(currentState)) {
      if (currentState is ProductInitial) {
        dynamic result = await repos.getProduct(
            start: 0, limit: event.limit, companyPartyId: event.companyPartyId);
        if (result is List<Product>) {
          products = result;
          yield ProductSuccess(
              products: result,
              hasReachedMax: result.length < event.limit ? true : false);
        } else
          yield ProductProblem(result);
        return;
      }
      if (currentState is ProductSuccess) {
        dynamic result = await repos.getProduct(
            start: currentState.products.length,
            limit: event.limit,
            companyPartyId: event.companyPartyId);
        if (result is List<Product>) {
          if (result.length < event.limit) {
            yield currentState.copyWith(
                products: currentState.products + result, hasReachedMax: true);
          } else {
            yield ProductSuccess().copyWith(
              products: currentState.products + result,
              hasReachedMax: false,
            );
          }
        } else
          yield ProductProblem(result);
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
            int index = currentState.products
                .indexWhere((prod) => prod.productId == result.productId);
            currentState.products.replaceRange(index, index + 1, [result]);
          }
          yield ProductSuccess(
                  products: currentState.products,
                  hasReachedMax: _hasReachedMax(currentState))
              .copyWith(message: 'product ' + (adding ? 'added' : 'updated'));
        } else {
          yield ProductProblem(result);
        }
      }
    } else if (event is DeleteProduct) {
      if (currentState is ProductSuccess) {
        int index = currentState.products
            .indexWhere((prod) => prod.productId == event.product.productId);
        String name = currentState.products[index].productName;
        yield ProductLoading('deleting product $name');
        dynamic result = await repos.deleteProduct(event.product.productId);
        if (result == event.product.productId) {
          currentState.products.removeAt(index);
          yield ProductSuccess(
                  products: currentState.products,
                  hasReachedMax: _hasReachedMax(currentState))
              .copyWith(message: 'Product $name deleted');
        } else {
          yield ProductProblem(result);
        }
      }
    }
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
  final String companyPartyId;
  final int limit;
  FetchProduct({this.companyPartyId, this.limit});
  @override
  String toString() => "FetchProduct company: $companyPartyId, limit: $limit";
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
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {
  final String message;
  ProductLoading([this.message]);
  @override
  List<Object> get props => [message];
  @override
  String toString() => 'Product loading...';
}

class ProductProblem extends ProductState {
  final String errorMessage;
  ProductProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  @override
  String toString() => 'ProductProblem { errorMessage $errorMessage }';
}

class ProductSuccess extends ProductState {
  final List<Product> products;
  final bool hasReachedMax;
  final String message;

  const ProductSuccess({this.products, this.hasReachedMax, this.message});

  ProductSuccess copyWith(
      {List<Product> products, bool hasReachedMax, String message}) {
    return ProductSuccess(
        products: products ?? this.products,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        message: message ?? this.message);
  }

  @override
  List<Object> get props => [products, hasReachedMax];

  @override
  String toString() => 'ProductSuccess { #products: ${products?.length}, '
      'hasReachedMax: $hasReachedMax }';
}
