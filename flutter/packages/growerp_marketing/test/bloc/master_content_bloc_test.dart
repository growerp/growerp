import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<MasterContentState> contentState(
  MasterContentStatus status, {
  List<MasterContent>? contents,
  String? message,
}) {
  var m = isA<MasterContentState>().having((s) => s.status, 'status', status);
  if (contents != null) {
    m = m.having((s) => s.masterContents, 'masterContents', contents);
  }
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final picture = Uint8List.fromList([7, 7]);
  final article = MasterContent(
    masterContentId: 'MC1',
    contentType: 'POSTING',
    pnpType: 'OTHER',
    status: 'DRAFT',
    title: 'Article',
    image: picture,
  );
  final planned = MasterContent(
    masterContentId: 'MC2',
    contentType: 'POSTING',
    pnpType: 'OTHER',
    status: 'PLANNED',
    title: 'Outline',
  );

  setUp(() => restClient = MockRestClient());

  MasterContentBloc build() => MasterContentBloc(restClient);

  group('MasterContentFetch', () {
    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentFetch_plan_loadsFirstPage',
      setUp: () =>
          when(
            () => restClient.getMasterContents(
              start: 0,
              limit: 20,
              searchString: '',
              planId: 'CP1',
            ),
          ).thenAnswer(
            (_) async => MasterContents(masterContents: [article, planned]),
          ),
      build: build,
      act: (bloc) => bloc.add(const MasterContentFetch(planId: 'CP1')),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success, contents: [article, planned]),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () =>
            restClient.getMasterContents(start: 0, limit: 20, searchString: ''),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const MasterContentFetch()),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.failure, message: 'No access'),
      ],
    );
  });

  group('MasterContentCreate / Update / Delete', () {
    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentCreate_withImage_sendsBase64AndInsertsFirst',
      setUp: () => when(
        () => restClient.createMasterContent(
          contentType: 'POSTING',
          pnpType: 'OTHER',
          status: 'DRAFT',
          title: 'Article',
          image: base64Encode(picture),
        ),
      ).thenAnswer((_) async => article),
      build: build,
      seed: () => MasterContentState(masterContents: [planned]),
      act: (bloc) => bloc.add(
        MasterContentCreate(
          MasterContent(
            contentType: 'POSTING',
            pnpType: 'OTHER',
            status: 'DRAFT',
            title: 'Article',
            image: picture,
          ),
        ),
      ),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success, contents: [article, planned]),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentUpdate_emptyImage_sendsEmptyStringToRemoveIt',
      setUp: () => when(
        () => restClient.updateMasterContent(
          masterContentId: 'MC1',
          contentType: 'POSTING',
          pnpType: 'OTHER',
          status: 'DRAFT',
          title: 'Article',
          image: '',
        ),
      ).thenAnswer((_) async => article.copyWith(image: Uint8List(0))),
      build: build,
      seed: () => MasterContentState(masterContents: [article]),
      act: (bloc) =>
          bloc.add(MasterContentUpdate(article.copyWith(image: Uint8List(0)))),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteMasterContent(masterContentId: 'MC1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => MasterContentState(masterContents: [article, planned]),
      act: (bloc) => bloc.add(MasterContentDelete(article)),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success, contents: [planned]),
      ],
    );
  });

  group('MasterContentGenerateWithAI', () {
    final written = MasterContent(
      masterContentId: 'MC2',
      contentType: 'POSTING',
      pnpType: 'OTHER',
      status: 'DRAFT',
      title: 'Written',
      body: 'Body',
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentGenerateWithAI_plannedPiece_replacesOutlineAsDraft',
      setUp: () => when(
        () => restClient.generateMasterContentWithAI(
          masterContentId: 'MC2',
          contentType: 'POSTING',
          pnpType: 'OTHER',
        ),
      ).thenAnswer((_) async => written),
      build: build,
      seed: () => MasterContentState(masterContents: [article, planned]),
      act: (bloc) =>
          bloc.add(const MasterContentGenerateWithAI(masterContentId: 'MC2')),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success).having(
          (s) => s.masterContents.map((m) => '${m.title}:${m.status}'),
          'contents',
          ['Article:DRAFT', 'Written:DRAFT'],
        ),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentGenerateWithAI_new_insertsFirst',
      setUp: () => when(
        () => restClient.generateMasterContentWithAI(
          personaId: 'P1',
          contentType: 'POSTING',
          pnpType: 'OTHER',
          brief: 'ERP tips',
        ),
      ).thenAnswer((_) async => written),
      build: build,
      seed: () => MasterContentState(masterContents: [article]),
      act: (bloc) => bloc.add(
        const MasterContentGenerateWithAI(personaId: 'P1', brief: 'ERP tips'),
      ),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success, contents: [written, article]),
      ],
    );
  });

  group('MasterContentAdaptForPlatform / Approve', () {
    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentAdaptForPlatform_jsonStringBody_reportsCountAndRefetches',
      setUp: () {
        when(
          () => restClient.adaptContentForPlatform(
            masterContentId: 'MC1',
            platforms: ['LINKEDIN', 'X'],
          ),
        ).thenAnswer((_) async => jsonEncode({'adaptedCount': 2}));
        when(
          () => restClient.getMasterContents(
            start: 0,
            limit: 20,
            searchString: '',
          ),
        ).thenAnswer((_) async => MasterContents(masterContents: [article]));
      },
      build: build,
      act: (bloc) => bloc.add(
        const MasterContentAdaptForPlatform(
          masterContentId: 'MC1',
          platforms: ['LINKEDIN', 'X'],
        ),
      ),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(
          MasterContentStatus.success,
          message: 'Adapted to 2 platform(s)',
        ).having((s) => s.adaptResults?['adaptedCount'], 'adapted', 2),
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success, contents: [article]),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentApprove_approve_keepsLocalImage',
      setUp: () =>
          when(
            () => restClient.approveMasterContent(
              masterContentId: 'MC1',
              approve: 'Y',
            ),
          ).thenAnswer(
            (_) async => MasterContent(
              masterContentId: 'MC1',
              contentType: 'POSTING',
              pnpType: 'OTHER',
              status: 'APPROVED',
            ),
          ),
      build: build,
      seed: () => MasterContentState(masterContents: [article]),
      act: (bloc) =>
          bloc.add(const MasterContentApprove(masterContentId: 'MC1')),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success)
            .having((s) => s.masterContents.single.status, 'status', 'APPROVED')
            .having((s) => s.masterContents.single.image, 'image', picture),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentApprove_revoke_sendsN',
      setUp: () => when(
        () => restClient.approveMasterContent(
          masterContentId: 'MC1',
          approve: 'N',
        ),
      ).thenAnswer((_) async => article),
      build: build,
      seed: () => MasterContentState(masterContents: [article]),
      act: (bloc) => bloc.add(
        const MasterContentApprove(masterContentId: 'MC1', approve: false),
      ),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(
          MasterContentStatus.success,
          message: 'Master content approval revoked',
        ),
      ],
    );
  });

  group('MasterContentGenerateImage', () {
    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentGenerateImage_image_decodesIntoContent',
      setUp: () =>
          when(
            () => restClient.generateMasterContentImage(masterContentId: 'MC2'),
          ).thenAnswer(
            (_) async => jsonEncode({
              'image': base64Encode([1, 2]),
            }),
          ),
      build: build,
      seed: () => MasterContentState(masterContents: [planned]),
      act: (bloc) => bloc.add(const MasterContentGenerateImage('MC2')),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(
          MasterContentStatus.success,
        ).having((s) => s.masterContents.single.image, 'image', [1, 2]),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentGenerateImage_noImage_reportsImageError',
      setUp: () => when(
        () => restClient.generateMasterContentImage(masterContentId: 'MC2'),
      ).thenAnswer((_) async => {'imageError': 'quota'}),
      build: build,
      act: (bloc) => bloc.add(const MasterContentGenerateImage('MC2')),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(
          MasterContentStatus.failure,
          message: 'No image generated: quota',
        ),
      ],
    );
  });

  group('MasterContentExport / Import', () {
    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentExport_zip_setsExportFile',
      setUp: () => when(() => restClient.exportMasterContents()).thenAnswer(
        (_) async => jsonEncode({
          'fileName': 'content.zip',
          'zip': base64Encode([9, 9]),
        }),
      ),
      build: build,
      act: (bloc) => bloc.add(const MasterContentExport()),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success)
            .having((s) => s.exportFile?.name, 'name', 'content.zip')
            .having((s) => s.exportFile?.bytes, 'bytes', [9, 9]),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentImport_zip_reportsCountsAndRefetches',
      setUp: () {
        when(
          () => restClient.importMasterContents(zip: base64Encode([9, 9])),
        ).thenAnswer(
          (_) async => jsonEncode({'createdCount': 3, 'updatedCount': 1}),
        );
        when(
          () => restClient.getMasterContents(
            start: 0,
            limit: 20,
            searchString: '',
          ),
        ).thenAnswer((_) async => MasterContents(masterContents: [article]));
      },
      build: build,
      act: (bloc) => bloc.add(MasterContentImport(Uint8List.fromList([9, 9]))),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(
          MasterContentStatus.success,
          message: 'Imported: 3 new, 1 changed',
        ),
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.success, contents: [article]),
      ],
    );

    blocTest<MasterContentBloc, MasterContentState>(
      'MasterContentImport_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.importMasterContents(zip: base64Encode([9, 9])),
      ).thenThrow(dioError('Bad zip')),
      build: build,
      act: (bloc) => bloc.add(MasterContentImport(Uint8List.fromList([9, 9]))),
      expect: () => [
        contentState(MasterContentStatus.loading),
        contentState(MasterContentStatus.failure, message: 'Bad zip'),
      ],
    );
  });
}
