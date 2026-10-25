import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_order_accounting/src/findoc/blocs/invoice_upload/invoice_upload_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<InvoiceUploadState> uploadState(
  InvoiceUploadStatus status, {
  String? message,
}) {
  var m = isA<InvoiceUploadState>().having((s) => s.status, 'status', status);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  final image = XFile.fromData(Uint8List.fromList([1, 2, 3]));

  InvoiceUploadImage upload() => InvoiceUploadImage(
    image: image,
    prompt: 'extract',
    mimeType: 'image/png',
  );

  void stubProcess(Future<String> Function(Invocation) answer) => when(
    () => restClient.processInvoiceImage(
      imageData: base64Encode([1, 2, 3]),
      prompt: 'extract',
      mimeType: 'image/png',
    ),
  ).thenAnswer(answer);

  group('InvoiceUploadImage', () {
    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_validJson_sendsBase64AndStoresExtractedData',
      setUp: () => stubProcess((_) async => '{"supplier": "Acme"}'),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) => bloc.add(upload()),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(
          InvoiceUploadStatus.success,
        ).having((s) => s.extractedData, 'extractedData', {'supplier': 'Acme'}),
      ],
    );

    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_restThrowsDio_emitsFailure',
      setUp: () => stubProcess((_) async => throw dioError('AI unavailable')),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) => bloc.add(upload()),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.failure, message: 'AI unavailable'),
      ],
    );

    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_invalidJson_emitsFailure',
      setUp: () => stubProcess((_) async => 'not json'),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) => bloc.add(upload()),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.failure),
      ],
    );
  });

  group('InvoiceCreate', () {
    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceCreate_extractedData_createsInvoice',
      setUp: () =>
          when(
            () => restClient.createInvoiceFromData(
              invoiceData: {'supplier': 'Acme'},
            ),
          ).thenAnswer(
            (_) async =>
                '{"docType": "invoice", "invoiceId": "I1", "sales": false}',
          ),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) => bloc.add(
        const InvoiceCreate({
          'extractedData': {'supplier': 'Acme'},
        }),
      ),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(
          InvoiceUploadStatus.success,
        ).having((s) => s.invoice?.invoiceId, 'invoiceId', 'I1'),
      ],
    );

    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceCreate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () =>
            restClient.createInvoiceFromData(invoiceData: {'supplier': 'Acme'}),
      ).thenThrow(dioError('Supplier unknown')),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) => bloc.add(
        const InvoiceCreate({
          'extractedData': {'supplier': 'Acme'},
        }),
      ),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.failure, message: 'Supplier unknown'),
      ],
    );
  });
}
