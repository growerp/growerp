/* This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final repos;
  List<ProductCategory>? categories;

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
    final CategoryState currentState = state;
    if (event is FetchCategory) {
      if (currentState is CategoryInitial) {
        dynamic result = await repos.getCategory(
            start: 0, limit: event.limit, companyPartyId: event.companyPartyId);
        if (result is List<ProductCategory>) {
          categories = result;
          yield CategorySuccess(
              categories: result,
              hasReachedMax: result.length < event.limit ? true : false);
        } else
          yield CategoryProblem(result);
        return;
      } else if (currentState is CategorySuccess) {
        if (event.search != null && currentState.search == null ||
            (currentState.search != null &&
                event.search != currentState.search)) {
          yield CategoryLoading();
          dynamic result = await repos.getCategory(
              start: 0,
              limit: event.limit,
              companyPartyId: event.companyPartyId,
              search: event.search);
          if (result is List<ProductCategory>) {
            categories = result;
            yield CategorySuccess(
                categories: result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield CategoryProblem(result);
          return;
        } else if (!_hasReachedMax(currentState)) {
          dynamic result = await repos.getCategory(
              start: currentState.categories!.length,
              limit: event.limit,
              search: event.search,
              companyPartyId: event.companyPartyId);
          if (result is List<ProductCategory>) {
            yield currentState.copyWith(
                categories: currentState.categories! + result,
                search: event.search,
                hasReachedMax: result.length < event.limit ? true : false);
          } else
            yield CategoryProblem(result);
        }
      }
    } else if (event is UpdateCategory) {
      bool adding = event.category.categoryId == null;
      yield CategoryLoading((adding ? 'adding' : 'updating') +
          ' category ${event.category.categoryName}');
      dynamic result = await repos.updateCategory(event.category);
      if (result is ProductCategory) {
        if (event.category.categoryId == null) {
          categories?.add(result);
        } else {
          int index = categories!
              .indexWhere((prod) => prod.categoryId == result.categoryId);
          categories!.replaceRange(index, index + 1, [result]);
        }
        yield CategorySuccess(
            categories: categories,
            hasReachedMax: _hasReachedMax(currentState),
            message: 'Category ' + (adding ? 'added' : 'updated'));
      } else {
        yield CategoryProblem(result);
      }
    } else if (event is DeleteCategory) {
      if (currentState is CategorySuccess) {
        int index = currentState.categories!
            .indexWhere((cat) => cat.categoryId == event.category.categoryId);
        String? name = currentState.categories![index].categoryName;
        yield CategoryLoading('deleting category $name');
        dynamic result = await repos.deleteCategory(event.category.categoryId);
        if (result == event.category.categoryId) {
          currentState.categories!.removeAt(index);
          yield CategorySuccess(categories: categories)
              .copyWith(message: 'Category $name deleted');
        } else {
          yield CategoryProblem(result);
        }
      }
    } else
      print("===Event $event not found");
  }
}

bool _hasReachedMax(CategoryState state) =>
    state is CategorySuccess && state.hasReachedMax!;

//#######################events###########################
abstract class CategoryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchCategory extends CategoryEvent {
  final String? companyPartyId;
  final int limit;
  final String? search;
  FetchCategory({this.companyPartyId, this.limit = 20, this.search});
  @override
  String toString() => "FetchCategory company: $companyPartyId, "
      "limit: $limit search: $search";
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
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {
  final String? message;
  CategoryLoading([this.message]);
  @override
  List<Object?> get props => [message];
  @override
  String toString() => 'Category loading...';
}

class CategoryProblem extends CategoryState {
  final String? errorMessage;
  CategoryProblem(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
  @override
  String toString() => 'CategoryProblem { errorMessage $errorMessage }';
}

class CategorySuccess extends CategoryState {
  final List<ProductCategory>? categories;
  final bool? hasReachedMax;
  final String? message;
  final String? search;

  const CategorySuccess(
      {this.categories, this.hasReachedMax, this.message, this.search});

  CategorySuccess copyWith(
      {List<ProductCategory>? categories,
      bool? hasReachedMax,
      String? message,
      String? search}) {
    return CategorySuccess(
        categories: categories ?? this.categories,
        hasReachedMax: hasReachedMax ?? this.hasReachedMax,
        message: message ?? this.message,
        search: search ?? this.search);
  }

  @override
  List<Object?> get props => [categories, hasReachedMax];

  @override
  String toString() => 'CategorySuccess { #categories: ${categories!.length}, '
      'hasReachedMax: $hasReachedMax }';
}
