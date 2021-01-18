import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:rxdart/rxdart.dart';
import '../blocs/@blocs.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final repos;
  final CategoryBloc categoryBloc;
  StreamSubscription categoryBlocSubscription;
  List<Product> products;
  List<ProductCategory> categories;

  ProductBloc(this.repos, this.categoryBloc) : super(ProductInitial()) {
    categoryBlocSubscription = categoryBloc.listen((state) {
      if (state is CategorySuccess) {
        categories = state.categories;
        add(CategoriesForProductUpdated(
            (categoryBloc.state as CategorySuccess).categories));
      }
    });
  }

  @override
  Future<void> close() {
    categoryBlocSubscription.cancel();
    return super.close();
  }

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
    if (event is ProductFetched && !_hasReachedMax(currentState)) {
      if (currentState is ProductInitial) {
        dynamic result = await repos.getProduct(
            start: 0,
            limit: event.productLimit,
            companyPartyId: event.companyPartyId);
        if (result is List<Product>) {
          products = result;
          yield ProductSuccess(
              categories: categories,
              products: result,
              hasReachedMax: result.length < event.productLimit ? true : false);
        } else
          yield ProductProblem(result);
        return;
      }
      if (currentState is ProductSuccess) {
        dynamic result = await repos.getProduct(
            start: currentState.products.length,
            limit: event.productLimit,
            companyPartyId: event.companyPartyId);
        if (result is List<Product>) {
          if (result.length < event.productLimit) {
            yield currentState.copyWith(hasReachedMax: true);
          } else {
            products = currentState.products + result;
            yield ProductSuccess(
              categories: categories,
              products: products,
              hasReachedMax: false,
            ).copyWith(hasReachedMax: false);
          }
        } else
          yield ProductProblem(result);
      }
    } else if (event is UpdateProduct) {
      dynamic result = await repos.updateProduct(event.product);
      if (result is Product) {
        if (event.product?.productId == null) {
          products?.add(event.product);
        } else {
          int index =
              products.indexWhere((prod) => prod.productId == result.productId);
          products.replaceRange(index, index + 1, [event.product]);
        }
        yield ProductSuccess(
            products: products, hasReachedMax: _hasReachedMax(currentState));
      } else {
        yield ProductProblem(result);
      }
    } else if (event is DeleteProduct) {
      dynamic result = await repos.deleteProduct(event.product.productId);
      if (result == event.product.productId) {
        yield ProductSuccess(
            products: products, hasReachedMax: _hasReachedMax(currentState));
      } else {
        yield ProductProblem(result);
      }
    } else if (event is CategoriesForProductUpdated) {
      yield ProductSuccess(
          products: products,
          categories: categories,
          hasReachedMax: _hasReachedMax(currentState));
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

class ProductFetched extends ProductEvent {
  final String companyPartyId;
  final int productLimit;
  ProductFetched(this.companyPartyId, this.productLimit);
  @override
  String toString() =>
      "ProductFetched company: $companyPartyId, productLimit: $productLimit";
}

class CategoriesForProductUpdated extends ProductEvent {
  final List<ProductCategory> categories;
  CategoriesForProductUpdated(this.categories);
  @override
  String toString() =>
      "CategoriesForProductUpdated: #categories: ${categories.length}";
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

class ProductProblem extends ProductState {
  final String errorMessage;
  ProductProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  @override
  String toString() => 'ProductProblem { errorMessage $errorMessage }';
}

class ProductSuccess extends ProductState {
  final Product product;
  final List<Product> products;
  final List<ProductCategory> categories;
  final bool hasReachedMax;

  const ProductSuccess({
    this.product,
    this.products,
    this.categories,
    this.hasReachedMax,
  });

  ProductSuccess copyWith({
    List<Product> products,
    bool hasReachedMax,
  }) {
    return ProductSuccess(
      categories: categories ?? this.categories,
      product: product ?? this.product,
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [product, products, categories, hasReachedMax];

  @override
  String toString() => 'ProductSuccess { product: $product '
      '#products: ${products?.length}, '
      '#categories: ${categories?.length} hasReachedMax: $hasReachedMax }';
}
