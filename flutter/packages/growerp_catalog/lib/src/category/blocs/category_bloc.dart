/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part 'category_event.dart';
part 'category_state.dart';

const _categorySearchDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> categoryDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

EventTransformer<CategorySearchChanged> categorySearchDebounce() {
  return (events, mapper) {
    final clearStream = events.where((e) => e.searchString.isEmpty);
    final searchStream = events
        .where((e) => e.searchString.length >= 3)
        .debounce(_categorySearchDebounceDuration);
    return clearStream.merge(searchStream).switchMap(mapper);
  };
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(this.restClient, this.applicationId)
    : super(const CategoryState()) {
    on<CategoryFetch>(
      _onCategoryFetch,
      transformer: categoryDroppable(const Duration(milliseconds: 100)),
    );
    on<CategoryUpdate>(_onCategoryUpdate);
    on<CategoryDelete>(_onCategoryDelete);
    on<CategoryUpload>(_onCategoryUpload);
    on<CategoryDownload>(_onCategoryDownload);
    on<CategorySearchChanged>(
      _onCategorySearchChanged,
      transformer: categorySearchDebounce(),
    );
  }

  final RestClient restClient;
  final String applicationId;
  int start = 0;

  Future<void> _onCategoryFetch(
    CategoryFetch event,
    Emitter<CategoryState> emit,
  ) async {
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
        isForDropDown: event.isForDropDown,
      );
      emit(
        state.copyWith(
          status: CategoryStatus.success,
          categories: current..addAll(compResult.categories),
          hasReachedMax: compResult.categories.length < event.limit,
          searchString: '',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCategorySearchChanged(
    CategorySearchChanged event,
    Emitter<CategoryState> emit,
  ) async {
    return _onCategoryFetch(
      CategoryFetch(
        searchString: event.searchString,
        companyPartyId: event.companyPartyId,
        refresh: true,
        limit: event.limit,
      ),
      emit,
    );
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
          category: event.category,
          applicationId: applicationId,
        );

        int index = categories.indexWhere(
          (element) => element.categoryId == event.category.categoryId,
        );
        categories[index] = compResult;

        emit(
          state.copyWith(
            status: CategoryStatus.success,
            categories: categories,
            message: 'categoryUpdateSuccess:${event.category.categoryName}',
          ),
        );
      } else {
        // add
        Category compResult = await restClient.createCategory(
          category: event.category,
          applicationId: applicationId,
        );

        categories.insert(0, compResult);
        emit(
          state.copyWith(
            status: CategoryStatus.success,
            categories: categories,
            message: 'categoryAddSuccess:${event.category.categoryName}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: await getDioError(e),
        ),
      );
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
        (element) => element.categoryId == event.category.categoryId,
      );
      categories.removeAt(index);
      emit(
        state.copyWith(
          status: CategoryStatus.success,
          categories: categories,
          message: 'categoryDeleteSuccess:${event.category.categoryName}',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: await getDioError(e),
        ),
      );
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
          categories.add(
            Category(
              categoryName: row[0],
              description: row[1],
              image: const Base64Decoder().convert(row[2]),
            ),
          );
        }
      }
      await restClient.importCategories(categories);

      emit(
        state.copyWith(
          status: CategoryStatus.success,
          message: 'Categories imported',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onCategoryDownload(
    CategoryDownload event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CategoryStatus.loading));

      await restClient.exportScreenCategories(
        applicationId: applicationId,
      );

      emit(
        state.copyWith(
          status: CategoryStatus.success,
          message: "The request is scheduled and the email be be sent shortly",
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: CategoryStatus.failure,
          categories: [],
          message: await getDioError(e),
        ),
      );
    }
  }
}
