import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/@models.dart';
import 'package:rxdart/rxdart.dart';

const limit = 10000;

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
    if (event is FetchCategory && !_hasReachedMax(currentState)) {
      if (currentState is CategoryInitial) {
        dynamic result = await repos.getCategory(
            start: 0, limit: event.limit, companyPartyId: event.companyPartyId);
        if (result is List<ProductCategory>) {
          categories = result;
          yield CategorySuccess(
              categories: result,
              hasReachedMax: result.length < limit ? true : false);
        } else
          yield CategoryProblem(result);
        return;
      }
      if (currentState is CategorySuccess) {
        dynamic result = await repos.getCategory(
            start: 0, limit: event.limit, companyPartyId: event.companyPartyId);
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
      bool adding = event.category.categoryId == null;
      yield CategoryLoading((adding ? 'adding' : 'updating') +
          ' category ${event.category.categoryName}');
      dynamic result = await repos.updateCategory(event.category);
      if (result is ProductCategory) {
        if (event.category?.categoryId == null) {
          categories?.add(result);
        } else {
          int index = categories
              .indexWhere((prod) => prod.categoryId == result.categoryId);
          categories.replaceRange(index, index + 1, [result]);
        }
        yield CategorySuccess(
            categories: categories,
            hasReachedMax: _hasReachedMax(currentState));
      } else {
        yield CategoryProblem(result);
      }
    } else if (event is DeleteCategory) {
      if (currentState is CategorySuccess) {
        int index = currentState.categories
            .indexWhere((cat) => cat.categoryId == event.category.categoryId);
        String name = currentState.categories[index].categoryName;
        yield CategoryLoading('deleting category $name');
        dynamic result = await repos.deleteCategory(event.category.categoryId);
        if (result == event.category.categoryId) {
          currentState.categories.removeAt(index);
          yield CategorySuccess(categories: categories)
              .copyWith(message: 'Category $name deleted');
        } else {
          yield CategoryProblem(result);
        }
      }
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

class FetchCategory extends CategoryEvent {
  final String companyPartyId;
  final int limit;
  FetchCategory({this.companyPartyId, this.limit});
  @override
  String toString() => "FetchCategory company: $companyPartyId";
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

class CategoryLoading extends CategoryState {
  final String message;
  CategoryLoading([this.message]);
  @override
  List<Object> get props => [message];
  @override
  String toString() => 'Category loading...';
}

class CategoryProblem extends CategoryState {
  final String errorMessage;
  CategoryProblem(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
  @override
  String toString() => 'CategoryProblem { errorMessage $errorMessage }';
}

class CategorySuccess extends CategoryState {
  final List<ProductCategory> categories;
  final bool hasReachedMax;
  final String message;

  const CategorySuccess({this.categories, this.hasReachedMax, this.message});

  CategorySuccess copyWith(
      {List<ProductCategory> categories, bool hasReachedMax, String message}) {
    return CategorySuccess(
        categories: categories ?? this.categories,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        message: message ?? this.message);
  }

  @override
  List<Object> get props => [categories, hasReachedMax];

  @override
  String toString() => 'CategorySuccess { #categories: ${categories.length}, '
      'hasReachedMax: $hasReachedMax }';
}
