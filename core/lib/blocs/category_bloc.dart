import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/models.dart';
import 'package:rxdart/rxdart.dart';
import '../blocs/@blocs.dart';

const _categoryLimit = 10000;

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final repos;
  List<ProductCategory> categories;

  CategoryBloc(this.repos) : super(CategoryInitial());

  @override
  Stream<Transition<CategoryEvent, CategoryState>> transformEvents(
    Stream<CategoryEvent> events,
    TransitionFunction<CategoryEvent, CategoryState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<CategoryState> mapEventToState(CategoryEvent event) async* {
    final currentState = state;
    if (event is CategoryFetched && !_hasReachedMax(currentState)) {
      if (currentState is CategoryInitial) {
        dynamic result =
            await repos.getCategory(0, _categoryLimit, event.companyPartyId);
        if (result is List<ProductCategory>) {
          categories = result;
          yield CategorySuccess(
              categories: result,
              hasReachedMax: result.length < _categoryLimit ? true : false);
        } else
          yield CategoryProblem(result);
        return;
      }
      if (currentState is CategorySuccess) {
        dynamic result = await repos.getCategory(
            currentState.categories.length, _categoryLimit);
        if (result is List<ProductCategory>) {
          if (result.isEmpty) {
            yield currentState.copyWith(hasReachedMax: true);
          } else {
            categories = currentState.categories + result;
            yield CategorySuccess(
              categories: categories,
              hasReachedMax: false,
            );
          }
        } else
          yield CategoryProblem(result);
      }
    } else if (event is UpdateCategory) {
      dynamic result = await repos.updateCategory(event.category);
      if (result is ProductCategory) {
        if (event.category?.categoryId == null) {
          categories?.add(event.category);
        } else {
          int index = categories
              .indexWhere((prod) => prod.categoryId == result.categoryId);
          categories.replaceRange(index, index + 1, [event.category]);
        }
        yield CategorySuccess(
            categories: categories,
            hasReachedMax: _hasReachedMax(currentState));
      } else {
        yield CategoryProblem(result);
      }
    } else if (event is DeleteCategory) {
      dynamic result = await repos.deleteCategory(event.category.categoryId);
      if (result == event.category.categoryId) {
        yield CategorySuccess(categories: categories);
      } else {
        yield CategoryProblem(result);
      }
    } else if (event is CategoriesForProductUpdated) {
      yield CategorySuccess(
          categories: categories, hasReachedMax: _hasReachedMax(currentState));
    }
  }
}

bool _hasReachedMax(CategoryState state) =>
    state is CategorySuccess && state.hasReachedMax;

//#######################events###########################
abstract class CategoryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class CategoryFetched extends CategoryEvent {
  final String companyPartyId;
  CategoryFetched(this.companyPartyId);
  @override
  String toString() => "CategoryFetched company: $companyPartyId";
}

class DeleteCategory extends CategoryEvent {
  final ProductCategory category;
  DeleteCategory(this.category);
  @override
  String toString() => "DeleteCategory: $category";
}

class UpdateCategory extends CategoryEvent {
  final ProductCategory category;
  UpdateCategory(this.category);
  @override
  String toString() => "UpdateCategory: $category";
}

//#######################state############################
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryProblem extends CategoryState {
  final String errorMessage;
  CategoryProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  @override
  String toString() => 'CategoryProblem { errorMessage $errorMessage }';
}

class CategorySuccess extends CategoryState {
  final ProductCategory category;
  final List<ProductCategory> categories;
  final bool hasReachedMax;

  const CategorySuccess({
    this.category,
    this.categories,
    this.hasReachedMax,
  });

  CategorySuccess copyWith({
    List<ProductCategory> categories,
    bool hasReachedMax,
  }) {
    return CategorySuccess(
      categories: categories ?? this.categories,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [categories, hasReachedMax];

  @override
  String toString() => 'CategorySuccess { #categories: ${categories.length}, '
      'category: $category hasReachedMax: $hasReachedMax }';
}
