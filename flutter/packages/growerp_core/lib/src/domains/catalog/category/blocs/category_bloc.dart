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
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'category_event.dart';
part 'category_state.dart';

const _categoryLimit = 20;

EventTransformer<E> categoryDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(
    this.restClient,
    this.classificationId,
  ) : super(const CategoryState()) {
    on<CategoryFetch>(_onCategoryFetch,
        transformer: categoryDroppable(const Duration(milliseconds: 100)));
    on<CategoryUpdate>(_onCategoryUpdate);
    on<CategoryDelete>(_onCategoryDelete);
    on<CategoryUpload>(_onCategoryUpload);
    on<CategoryDownload>(_onCategoryDownload);
  }

  final RestClient restClient;
  final String classificationId;
  int start = 0;

  Future<void> _onCategoryFetch(
    CategoryFetch event,
    Emitter<CategoryState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh && event.searchString == '') {
      return;
    }
    List<Category> current = [];
    if (state.status == CategoryStatus.initial ||
        event.refresh ||
        event.searchString != '') {
      start = 0;
      current = [];
    } else {
      start = state.categories.length;
      current = List.of(state.categories);
    }
    try {
      Categories compResult = await restClient.getCategory(
          companyPartyId: event.companyPartyId,
          searchString: event.searchString,
          start: start,
          limit: event.limit,
          isForDropDown: event.isForDropDown);
      emit(state.copyWith(
        status: CategoryStatus.success,
        categories: current..addAll(compResult.categories),
        hasReachedMax: compResult.categories.length < event.limit,
        searchString: '',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CategoryStatus.failure, message: getDioError(e)));
    }
  }

  Future<void> _onCategoryUpdate(
    CategoryUpdate event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CategoryStatus.loading));

      List<Category> categories = List.from(state.categories);
      if (event.category.categoryId.isNotEmpty) {
        Category compResult = await restClient.updateCategory(
            category: event.category, classificationId: classificationId);

        int index = categories.indexWhere(
            (element) => element.categoryId == event.category.categoryId);
        categories[index] = compResult;

        emit(state.copyWith(
            status: CategoryStatus.success,
            categories: categories,
            message: 'Category ${event.category.categoryName} updated!'));
      } else {
        // add
        Category compResult = await restClient.createCategory(
            category: event.category, classificationId: classificationId);

        categories.insert(0, compResult);
        emit(state.copyWith(
            status: CategoryStatus.success,
            categories: categories,
            message: 'Category ${event.category.categoryName} added!'));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onCategoryDelete(
    CategoryDelete event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CategoryStatus.loading));
      List<Category> categories = List.from(state.categories);

      await restClient.deleteCategory(category: event.category);
      int index = categories.indexWhere(
          (element) => element.categoryId == event.category.categoryId);
      categories.removeAt(index);
      emit(state.copyWith(
          status: CategoryStatus.success,
          categories: categories,
          message: 'Category ${event.category.categoryName} deleted!'));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onCategoryUpload(
    CategoryUpload event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CategoryStatus.loading));
      List<Category> categories = [];
      final result = fast_csv.parse(event.file);
      int line = 0;
      // import csv into categories
      for (final row in result) {
        if (line++ < 2) continue;
        if (row.length > 1) {
          categories.add(Category(
              categoryName: row[0],
              description: row[1],
              image: const Base64Decoder().convert(row[2])));
        }
      }
      String compResult = await restClient.importScreenCategories(
          categories: categories, classificationId: classificationId);

      emit(state.copyWith(status: CategoryStatus.success, message: compResult));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: getDioError(e)));
    }
  }

  Future<void> _onCategoryDownload(
    CategoryDownload event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CategoryStatus.loading));

      await restClient.exportScreenCategories(
          classificationId: classificationId);

      emit(state.copyWith(
          status: CategoryStatus.success,
          message:
              "The request is scheduled and the email be be sent shortly"));
    } on DioException catch (e) {
      emit(state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: getDioError(e)));
    }
  }
}
