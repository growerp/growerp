import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
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

  final bytes = Uint8List.fromList([1, 2, 3]);

  // what the backend returns: a purchase invoice to review, not saved yet
  final invoice = FinDoc(
    docType: FinDocType.invoice,
    sales: false,
    reference: 'INV-77',
    otherCompany: Company(partyId: 'SUP1', name: 'Acme'),
    items: [
      FinDocItem(
        description: 'Paper',
        quantity: Decimal.parse('2'),
        price: Decimal.parse('3.5'),
      ),
    ],
  );

  void stubRead(String mimeType, Future<FinDoc> Function(Invocation) answer) =>
      when(
        () => restClient.getFinDocFromImage(
          imageData: base64Encode(bytes),
          mimeType: mimeType,
        ),
      ).thenAnswer(answer);

  group('InvoiceUploadImage', () {
    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_pngFile_sendsBase64AndReturnsInvoiceToReview',
      setUp: () => stubRead('image/png', (_) async => invoice),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) =>
          bloc.add(InvoiceUploadImage(XFile.fromData(bytes, path: 'scan.png'))),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(
          InvoiceUploadStatus.success,
        ).having((s) => s.finDoc, 'finDoc', invoice),
      ],
    );

    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_restThrowsDio_emitsFailure',
      setUp: () =>
          stubRead('image/png', (_) async => throw dioError('AI unavailable')),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) =>
          bloc.add(InvoiceUploadImage(XFile.fromData(bytes, path: 'scan.png'))),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.failure, message: 'AI unavailable'),
      ],
    );

    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_jpgFile_sendsJpegMimeType',
      setUp: () => stubRead('image/jpeg', (_) async => invoice),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) =>
          bloc.add(InvoiceUploadImage(XFile.fromData(bytes, path: 'bill.JPG'))),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.success),
      ],
    );
  });

  group('InvoiceUploadImage mime type', () {
    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_fileMimeType_winsOverName',
      setUp: () => stubRead('image/webp', (_) async => invoice),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) => bloc.add(
        InvoiceUploadImage(
          XFile.fromData(bytes, path: 'photo.jpg', mimeType: 'image/webp'),
        ),
      ),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.success),
      ],
    );

    blocTest<InvoiceUploadBloc, InvoiceUploadState>(
      'InvoiceUploadImage_unknownExtension_defaultsToJpeg',
      setUp: () => stubRead('image/jpeg', (_) async => invoice),
      build: () => InvoiceUploadBloc(restClient),
      act: (bloc) =>
          bloc.add(InvoiceUploadImage(XFile.fromData(bytes, path: 'camera'))),
      expect: () => [
        uploadState(InvoiceUploadStatus.loading),
        uploadState(InvoiceUploadStatus.success),
      ],
    );
  });
}
