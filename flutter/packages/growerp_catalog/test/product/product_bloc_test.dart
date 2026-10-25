import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// ProductFetch is throttled 100ms, ProductSearchChanged debounced 300ms.
const fetchWait = Duration(milliseconds: 150);
const searchWait = Duration(milliseconds: 400);

Matcher productState(
  ProductStatus status, {
  List<Product>? products,
  List<Uom>? uoms,
  String? message,
  bool? hasReachedMax,
}) {
  var m = isA<ProductState>().having((s) => s.status, 'status', status);
  if (products != null) m = m.having((s) => s.products, 'products', products);
  if (uoms != null) m = m.having((s) => s.uoms, 'uoms', uoms);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  if (hasReachedMax != null) {
    m = m.having((s) => s.hasReachedMax, 'hasReachedMax', hasReachedMax);
  }
  return m;
}

void main() {
  late MockRestClient restClient;

  void stubGetProduct({
    String searchString = '',
    int start = 0,
    int limit = 20,
    required Future<Products> Function(Invocation) answer,
  }) => when(
    () => restClient.getProduct(
      searchString: searchString,
      isForDropDown: false,
      assetClassId: '',
      start: start,
      limit: limit,
      applicationId: applicationId,
    ),
  ).thenAnswer(answer);

  void stubUoms() => when(
    () => restClient.getUom(productUomTypes),
  ).thenAnswer((_) async => Uoms(uoms: [kgUom]));

  setUpAll(() => registerFallbackValue(<Product>[]));
  setUp(() => restClient = MockRestClient());

  group('ProductFetch', () {
    blocTest<ProductBloc, ProductState>(
      'ProductFetch_initial_loadsProductsAndUoms',
      setUp: () {
        stubUoms();
        stubGetProduct(
          answer: (_) async => Products(products: [product1, product2]),
        );
      },
      build: () => ProductBloc(restClient, applicationId),
      act: (bloc) => bloc.add(const ProductFetch()),
      wait: fetchWait,
      // The initial fetch also fires ProductUom; both run concurrently, so
      // only the end state is deterministic.
      verify: (bloc) => expect(
        bloc.state,
        productState(
          ProductStatus.success,
          products: [product1, product2],
          uoms: [kgUom],
          hasReachedMax: true,
        ),
      ),
    );

    blocTest<ProductBloc, ProductState>(
      'ProductFetch_nextPage_appendsWithoutReloadingUoms',
      setUp: () => stubGetProduct(
        start: 1,
        limit: 1,
        answer: (_) async => Products(products: [product2]),
      ),
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1],
      ),
      act: (bloc) => bloc.add(const ProductFetch(limit: 1)),
      wait: fetchWait,
      expect: () => [
        productState(
          ProductStatus.success,
          products: [product1, product2],
          hasReachedMax: false,
        ),
      ],
      verify: (_) => verifyNever(() => restClient.getUom(any())),
    );

    blocTest<ProductBloc, ProductState>(
      'ProductFetch_restThrowsDio_emitsFailureAndClearsList',
      setUp: () => stubGetProduct(
        start: 1,
        answer: (_) async => throw dioError('Product service down'),
      ),
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1],
      ),
      act: (bloc) => bloc.add(const ProductFetch()),
      wait: fetchWait,
      expect: () => [
        productState(
          ProductStatus.failure,
          products: [],
          message: 'Product service down',
        ),
      ],
    );
  });

  group('ProductSearchChanged', () {
    blocTest<ProductBloc, ProductState>(
      'ProductSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () {
        stubUoms();
        stubGetProduct(
          searchString: 'App',
          answer: (_) async => Products(products: [product1]),
        );
      },
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1, product2],
      ),
      act: (bloc) => bloc.add(const ProductSearchChanged(searchString: 'App')),
      wait: searchWait,
      verify: (bloc) => expect(
        bloc.state,
        isA<ProductState>()
            .having((s) => s.products, 'products', [product1])
            .having((s) => s.searchString, 'searchString', 'App'),
      ),
    );
  });

  group('ProductUpdate', () {
    final changed = product1.copyWith(productName: 'Green apple');
    const newProduct = Product(productName: 'Plum');
    const created = Product(productId: 'P3', productName: 'Plum');

    blocTest<ProductBloc, ProductState>(
      'ProductUpdate_existingProduct_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateProduct(
          product: changed,
          applicationId: applicationId,
        ),
      ).thenAnswer((_) async => changed),
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1, product2],
      ),
      act: (bloc) => bloc.add(ProductUpdate(changed)),
      expect: () => [
        productState(ProductStatus.loading),
        productState(
          ProductStatus.success,
          products: [changed, product2],
          message: 'productUpdateSuccess:Green apple',
        ),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'ProductUpdate_newProduct_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createProduct(
          product: newProduct,
          applicationId: applicationId,
        ),
      ).thenAnswer((_) async => created),
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1],
      ),
      act: (bloc) => bloc.add(const ProductUpdate(newProduct)),
      expect: () => [
        productState(ProductStatus.loading),
        productState(
          ProductStatus.success,
          products: [created, product1],
          message: 'productAddSuccess:Plum',
        ),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'ProductUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createProduct(
          product: newProduct,
          applicationId: applicationId,
        ),
      ).thenThrow(dioError('Name already used')),
      build: () => ProductBloc(restClient, applicationId),
      act: (bloc) => bloc.add(const ProductUpdate(newProduct)),
      expect: () => [
        productState(ProductStatus.loading),
        productState(ProductStatus.failure, message: 'Name already used'),
      ],
    );
  });

  group('ProductDelete', () {
    blocTest<ProductBloc, ProductState>(
      'ProductDelete_existingProduct_removesIt',
      setUp: () => when(
        () => restClient.deleteProduct(product: product1),
      ).thenAnswer((_) async => product1),
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1, product2],
      ),
      act: (bloc) => bloc.add(const ProductDelete(product1)),
      expect: () => [
        productState(ProductStatus.loading),
        productState(
          ProductStatus.success,
          products: [product2],
          message: 'productDeleteSuccess:Apple',
        ),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'ProductDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteProduct(product: product1),
      ).thenThrow(dioError('Product on order')),
      build: () => ProductBloc(restClient, applicationId),
      seed: () => const ProductState(
        status: ProductStatus.success,
        products: [product1],
      ),
      act: (bloc) => bloc.add(const ProductDelete(product1)),
      expect: () => [
        productState(ProductStatus.loading),
        productState(ProductStatus.failure, message: 'Product on order'),
      ],
    );
  });

  group('ProductUpload', () {
    blocTest<ProductBloc, ProductState>(
      'ProductUpload_csv_importsRowsWithPricesAndCategories',
      setUp: () => when(
        () => restClient.importProducts(any(), applicationId),
      ).thenAnswer((_) async {}),
      build: () => ProductBloc(restClient, applicationId),
      act: (bloc) => bloc.add(
        const ProductUpload(
          'title\n'
          'name,descr,type,image,class,list,price,wh,count,cat1,cat2,cat3\n'
          'Apple,Red,PtGood,,,1.50,1.20,true,5,Fruit,,Fresh\n'
          'short,row\n',
        ),
      ),
      expect: () => [
        productState(ProductStatus.loading),
        productState(ProductStatus.success, message: 'Products imported.'),
      ],
      verify: (_) {
        final imported =
            verify(
                  () => restClient.importProducts(captureAny(), applicationId),
                ).captured.single
                as List<Product>;
        expect(imported, hasLength(1)); // short row skipped
        final apple = imported.single;
        expect(apple.productName, 'Apple');
        expect(apple.listPrice.toString(), '1.5');
        expect(apple.price.toString(), '1.2');
        expect(apple.useWarehouse, isTrue);
        expect(apple.assetCount, 5);
        expect(apple.categories.map((c) => c.categoryName), ['Fruit', 'Fresh']);
      },
    );
  });

  group('ProductDownload', () {
    blocTest<ProductBloc, ProductState>(
      'ProductDownload_scheduled_emitsSuccess',
      setUp: () => when(
        () => restClient.exportScreenProducts(applicationId: applicationId),
      ).thenAnswer((_) async => ''),
      build: () => ProductBloc(restClient, applicationId),
      act: (bloc) => bloc.add(ProductDownload()),
      expect: () => [
        productState(ProductStatus.loading),
        productState(ProductStatus.success),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'ProductDownload_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.exportScreenProducts(applicationId: applicationId),
      ).thenThrow(dioError('No email server')),
      build: () => ProductBloc(restClient, applicationId),
      act: (bloc) => bloc.add(ProductDownload()),
      expect: () => [
        productState(ProductStatus.loading),
        productState(ProductStatus.failure, message: 'No email server'),
      ],
    );
  });

  group('ProductUom', () {
    blocTest<ProductBloc, ProductState>(
      'ProductUom_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getUom(productUomTypes),
      ).thenThrow(dioError('Uom lookup failed')),
      build: () => ProductBloc(restClient, applicationId),
      act: (bloc) => bloc.add(const ProductUom(productUomTypes)),
      expect: () => [
        productState(ProductStatus.loading),
        productState(ProductStatus.failure, message: 'Uom lookup failed'),
      ],
    );
  });
}
