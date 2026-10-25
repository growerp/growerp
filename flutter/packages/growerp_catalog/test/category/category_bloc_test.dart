import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// CategoryFetch is throttled 100ms: give the handler time before asserting.
const fetchWait = Duration(milliseconds: 150);

Matcher categoryState(
  CategoryStatus status, {
  List<Category>? categories,
  String? message,
  bool? hasReachedMax,
}) {
  var m = isA<CategoryState>().having((s) => s.status, 'status', status);
  if (categories != null) {
    m = m.having((s) => s.categories, 'categories', categories);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  if (hasReachedMax != null) {
    m = m.having((s) => s.hasReachedMax, 'hasReachedMax', hasReachedMax);
  }
  return m;
}

void main() {
  late MockRestClient restClient;

  setUpAll(() => registerFallbackValue(Category()));
  setUp(() => restClient = MockRestClient());

  group('CategoryFetch', () {
    blocTest<CategoryBloc, CategoryState>(
      'CategoryFetch_firstPageShorterThanLimit_emitsSuccessAndReachedMax',
      setUp: () => when(
        () => restClient.getCategory(
          companyPartyId: '',
          searchString: '',
          start: 0,
          limit: 20,
          isForDropDown: false,
        ),
      ).thenAnswer((_) async => Categories(categories: [category1, category2])),
      build: () => CategoryBloc(restClient, applicationId),
      act: (bloc) => bloc.add(const CategoryFetch()),
      wait: fetchWait,
      expect: () => [
        categoryState(
          CategoryStatus.success,
          categories: [category1, category2],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategoryFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getCategory(
          companyPartyId: '',
          searchString: '',
          start: 1,
          limit: 1,
          isForDropDown: false,
        ),
      ).thenAnswer((_) async => Categories(categories: [category2])),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1],
      ),
      act: (bloc) => bloc.add(const CategoryFetch(limit: 1)),
      wait: fetchWait,
      expect: () => [
        categoryState(
          CategoryStatus.success,
          categories: [category1, category2],
          hasReachedMax: false,
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategoryFetch_restThrowsDio_emitsFailureWithBackendMessage',
      setUp: () => when(
        () => restClient.getCategory(
          companyPartyId: '',
          searchString: '',
          start: 0,
          limit: 20,
          isForDropDown: false,
        ),
      ).thenThrow(dioError('Category service down')),
      build: () => CategoryBloc(restClient, applicationId),
      act: (bloc) => bloc.add(const CategoryFetch()),
      wait: fetchWait,
      expect: () => [
        categoryState(CategoryStatus.failure, message: 'Category service down'),
      ],
    );
  });

  group('CategorySearchChanged', () {
    blocTest<CategoryBloc, CategoryState>(
      'CategorySearchChanged_threeChars_fetchesFromStartWithSearch',
      setUp: () => when(
        () => restClient.getCategory(
          companyPartyId: '',
          searchString: 'Fru',
          start: 0,
          limit: 20,
          isForDropDown: false,
        ),
      ).thenAnswer((_) async => Categories(categories: [category1])),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1, category2],
      ),
      act: (bloc) =>
          bloc.add(const CategorySearchChanged(searchString: 'Fru')),
      wait: const Duration(milliseconds: 400), // 300ms debounce
      expect: () => [
        categoryState(CategoryStatus.success, categories: [category1]),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategorySearchChanged_twoChars_doesNotFetch',
      build: () => CategoryBloc(restClient, applicationId),
      act: (bloc) => bloc.add(const CategorySearchChanged(searchString: 'Fr')),
      wait: const Duration(milliseconds: 400),
      expect: () => <CategoryState>[],
      verify: (_) => verifyNever(
        () => restClient.getCategory(
          companyPartyId: any(named: 'companyPartyId'),
          searchString: any(named: 'searchString'),
          start: any(named: 'start'),
          limit: any(named: 'limit'),
          isForDropDown: any(named: 'isForDropDown'),
        ),
      ),
    );
  });

  group('CategoryUpdate', () {
    final changed = category1.copyWith(categoryName: 'Fresh fruit');
    final created = Category(categoryId: 'C3', categoryName: 'Nuts');

    blocTest<CategoryBloc, CategoryState>(
      'CategoryUpdate_existingCategory_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateCategory(
          category: changed,
          applicationId: applicationId,
        ),
      ).thenAnswer((_) async => changed),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1, category2],
      ),
      act: (bloc) => bloc.add(CategoryUpdate(changed)),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(
          CategoryStatus.success,
          categories: [changed, category2],
          message: 'categoryUpdateSuccess:Fresh fruit',
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategoryUpdate_newCategory_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createCategory(
          category: Category(categoryName: 'Nuts'),
          applicationId: applicationId,
        ),
      ).thenAnswer((_) async => created),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1],
      ),
      act: (bloc) => bloc.add(CategoryUpdate(Category(categoryName: 'Nuts'))),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(
          CategoryStatus.success,
          categories: [created, category1],
          message: 'categoryAddSuccess:Nuts',
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategoryUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateCategory(
          category: changed,
          applicationId: applicationId,
        ),
      ).thenThrow(dioError('Not allowed')),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1],
      ),
      act: (bloc) => bloc.add(CategoryUpdate(changed)),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(CategoryStatus.failure, message: 'Not allowed'),
      ],
    );
  });

  group('CategoryDelete', () {
    blocTest<CategoryBloc, CategoryState>(
      'CategoryDelete_existingCategory_removesIt',
      setUp: () => when(
        () => restClient.deleteCategory(category: category1),
      ).thenAnswer((_) async => category1),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1, category2],
      ),
      act: (bloc) => bloc.add(CategoryDelete(category1)),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(
          CategoryStatus.success,
          categories: [category2],
          message: 'categoryDeleteSuccess:Fruit',
        ),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategoryDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteCategory(category: category1),
      ).thenThrow(dioError('Category has products')),
      build: () => CategoryBloc(restClient, applicationId),
      seed: () => CategoryState(
        status: CategoryStatus.success,
        categories: [category1],
      ),
      act: (bloc) => bloc.add(CategoryDelete(category1)),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(CategoryStatus.failure, message: 'Category has products'),
      ],
    );
  });

  group('CategoryUpload', () {
    blocTest<CategoryBloc, CategoryState>(
      'CategoryUpload_csvWithTwoHeaderLines_importsDataRows',
      setUp: () =>
          when(() => restClient.importCategories(any())).thenAnswer((_) async {}),
      build: () => CategoryBloc(restClient, applicationId),
      act: (bloc) => bloc.add(
        const CategoryUpload(
          'title\nname,description,image\nFruit,Sweet,AQI=\nNuts,Crunchy,\n',
        ),
      ),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(CategoryStatus.success, message: 'Categories imported'),
      ],
      verify: (_) {
        final imported =
            verify(() => restClient.importCategories(captureAny()))
                    .captured
                    .single
                as List<Category>;
        expect(imported.map((c) => c.categoryName), ['Fruit', 'Nuts']);
        expect(imported.first.image, [1, 2]);
      },
    );
  });

  group('CategoryDownload', () {
    blocTest<CategoryBloc, CategoryState>(
      'CategoryDownload_scheduled_emitsSuccess',
      setUp: () => when(
        () => restClient.exportScreenCategories(applicationId: applicationId),
      ).thenAnswer((_) async => ''),
      build: () => CategoryBloc(restClient, applicationId),
      act: (bloc) => bloc.add(CategoryDownload()),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(CategoryStatus.success),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'CategoryDownload_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.exportScreenCategories(applicationId: applicationId),
      ).thenThrow(dioError('No email server')),
      build: () => CategoryBloc(restClient, applicationId),
      act: (bloc) => bloc.add(CategoryDownload()),
      expect: () => [
        categoryState(CategoryStatus.loading),
        categoryState(CategoryStatus.failure, message: 'No email server'),
      ],
    );
  });
}
