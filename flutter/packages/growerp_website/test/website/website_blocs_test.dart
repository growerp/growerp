import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_website/growerp_website.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// WebsiteFetch and ContentFetch are throttled 100ms.
const fetchWait = Duration(milliseconds: 150);

void main() {
  late MockRestClient restClient;

  final website = Website(
    id: 'W1',
    hostName: 'acme.growerp.com',
    title: 'Acme',
  );

  setUpAll(() => registerFallbackValue(Obsidian()));
  setUp(() => restClient = MockRestClient());

  group('WebsiteBloc', () {
    TypeMatcher<WebsiteState> websiteState(
      WebsiteStatus status, {
      String? message,
    }) {
      var m = isA<WebsiteState>().having((s) => s.status, 'status', status);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    blocTest<WebsiteBloc, WebsiteState>(
      'WebsiteFetch_success_setsWebsite',
      setUp: () =>
          when(() => restClient.getWebsite()).thenAnswer((_) async => website),
      build: () => WebsiteBloc(restClient),
      act: (bloc) => bloc.add(WebsiteFetch()),
      wait: fetchWait,
      expect: () => [
        websiteState(WebsiteStatus.loading),
        websiteState(
          WebsiteStatus.success,
        ).having((s) => s.website, 'website', website),
      ],
    );

    blocTest<WebsiteBloc, WebsiteState>(
      'WebsiteFetch_restThrowsDio_emitsFailure',
      setUp: () =>
          when(() => restClient.getWebsite()).thenThrow(dioError('No site')),
      build: () => WebsiteBloc(restClient),
      act: (bloc) => bloc.add(WebsiteFetch()),
      wait: fetchWait,
      expect: () => [
        websiteState(WebsiteStatus.loading),
        websiteState(WebsiteStatus.failure, message: 'No site'),
      ],
    );

    blocTest<WebsiteBloc, WebsiteState>(
      'WebsiteUpdate_changedTitle_storesResult',
      setUp: () => when(
        () => restClient.updateWebsite(website: website.copyWith(title: 'New')),
      ).thenAnswer((_) async => website.copyWith(title: 'New')),
      build: () => WebsiteBloc(restClient),
      act: (bloc) => bloc.add(WebsiteUpdate(website.copyWith(title: 'New'))),
      expect: () => [
        websiteState(WebsiteStatus.loading),
        websiteState(
          WebsiteStatus.success,
          message: 'websiteUpdateSuccess',
        ).having((s) => s.website?.title, 'title', 'New'),
      ],
    );

    blocTest<WebsiteBloc, WebsiteState>(
      'WebsiteUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.updateWebsite(website: website),
      ).thenThrow(dioError('Host name taken')),
      build: () => WebsiteBloc(restClient),
      act: (bloc) => bloc.add(WebsiteUpdate(website)),
      expect: () => [
        websiteState(WebsiteStatus.loading),
        websiteState(WebsiteStatus.failure, message: 'Host name taken'),
      ],
    );

    blocTest<WebsiteBloc, WebsiteState>(
      'WebsiteObsUpload_noPath_removesObsidian',
      setUp: () => when(
        () => restClient.obsUpload(obsidian: Obsidian(title: 'notes')),
      ).thenAnswer((_) async => website),
      build: () => WebsiteBloc(restClient),
      act: (bloc) => bloc.add(WebsiteObsUpload(Obsidian(title: 'notes'), null)),
      expect: () => [
        websiteState(WebsiteStatus.loading),
        websiteState(WebsiteStatus.success, message: 'obsidian removed'),
      ],
    );

    late Directory tempDir;
    blocTest<WebsiteBloc, WebsiteState>(
      'WebsiteObsUpload_zipPath_sendsZipBytes',
      setUp: () {
        tempDir = Directory.systemTemp.createTempSync('obs');
        File('${tempDir.path}/vault.ZIP').writeAsBytesSync([1, 2, 3]);
        when(
          () => restClient.obsUpload(obsidian: any(named: 'obsidian')),
        ).thenAnswer((_) async => website);
      },
      tearDown: () => tempDir.deleteSync(recursive: true),
      build: () => WebsiteBloc(restClient),
      act: (bloc) => bloc.add(
        WebsiteObsUpload(Obsidian(title: 'notes'), '${tempDir.path}/vault.ZIP'),
      ),
      wait: const Duration(milliseconds: 200), // real file read
      expect: () => [
        websiteState(WebsiteStatus.loading),
        websiteState(
          WebsiteStatus.success,
          message: 'obsidian zip file uploaded..',
        ),
      ],
      verify: (_) {
        final sent =
            verify(
                  () => restClient.obsUpload(
                    obsidian: captureAny(named: 'obsidian'),
                  ),
                ).captured.single
                as Obsidian;
        expect(sent.zip, Uint8List.fromList([1, 2, 3]));
        expect(sent.title, 'notes');
      },
    );
  });

  group('ContentBloc', () {
    final page = Content(path: 'about', title: 'About');

    blocTest<ContentBloc, ContentState>(
      'ContentFetch_newContentNoPath_returnsItWithoutBackend',
      build: () => ContentBloc(restClient),
      act: (bloc) => bloc.add(ContentFetch('W1', Content(title: 'New'))),
      wait: fetchWait,
      expect: () => [
        isA<ContentState>().having((s) => s.status, 's', ContentStatus.loading),
        isA<ContentState>()
            .having((s) => s.status, 's', ContentStatus.success)
            .having((s) => s.content?.title, 'title', 'New'),
      ],
      verify: (_) => verifyZeroInteractions(restClient),
    );

    blocTest<ContentBloc, ContentState>(
      'ContentFetch_path_loadsFromBackend',
      setUp: () => when(
        () => restClient.getWebsiteContent(path: 'about', text: ''),
      ).thenAnswer((_) async => page.copyWith(text: '# About')),
      build: () => ContentBloc(restClient),
      act: (bloc) => bloc.add(ContentFetch('W1', page)),
      wait: fetchWait,
      expect: () => [
        isA<ContentState>(),
        isA<ContentState>().having((s) => s.content?.text, 'text', '# About'),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'ContentFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getWebsiteContent(path: 'about', text: ''),
      ).thenThrow(dioError('Not found')),
      build: () => ContentBloc(restClient),
      act: (bloc) => bloc.add(ContentFetch('W1', page)),
      wait: fetchWait,
      expect: () => [
        isA<ContentState>(),
        isA<ContentState>()
            .having((s) => s.status, 's', ContentStatus.failure)
            .having((s) => s.message, 'message', 'Not found'),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'ContentUpdate_page_uploadsAndReportsTitle',
      setUp: () => when(
        () => restClient.uploadWebsiteContent(content: page),
      ).thenAnswer((_) async => page),
      build: () => ContentBloc(restClient),
      act: (bloc) => bloc.add(ContentUpdate('W1', page)),
      expect: () => [
        isA<ContentState>().having(
          (s) => s.status,
          's',
          ContentStatus.updating,
        ),
        isA<ContentState>()
            .having((s) => s.status, 's', ContentStatus.success)
            .having((s) => s.message, 'message', 'contentUpdateSuccess:About'),
      ],
    );

    blocTest<ContentBloc, ContentState>(
      'ContentUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.uploadWebsiteContent(content: page),
      ).thenThrow(dioError('Too large')),
      build: () => ContentBloc(restClient),
      act: (bloc) => bloc.add(ContentUpdate('W1', page)),
      expect: () => [
        isA<ContentState>(),
        isA<ContentState>().having((s) => s.message, 'message', 'Too large'),
      ],
    );
  });

  group('WebsiteFormBloc', () {
    final contact = WebsiteForm(formId: 'F1', formName: 'contact');
    final quote = WebsiteForm(formId: 'F2', formName: 'quote');

    TypeMatcher<WebsiteFormState> formState(
      WebsiteFormStatus status, {
      List<WebsiteForm>? forms,
      String? message,
    }) {
      var m = isA<WebsiteFormState>().having((s) => s.status, 'status', status);
      if (forms != null) m = m.having((s) => s.webForms, 'webForms', forms);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    blocTest<WebsiteFormBloc, WebsiteFormState>(
      'WebsiteFormFetch_search_setsForms',
      setUp: () => when(
        () => restClient.getWebsiteForm(searchString: 'con', limit: 20),
      ).thenAnswer((_) async => WebsiteForms(webForms: [contact])),
      build: () => WebsiteFormBloc(restClient),
      act: (bloc) => bloc.add(const WebsiteFormFetch(searchString: 'con')),
      expect: () => [
        formState(WebsiteFormStatus.loading),
        formState(WebsiteFormStatus.success, forms: [contact]),
      ],
    );

    blocTest<WebsiteFormBloc, WebsiteFormState>(
      'WebsiteFormFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getWebsiteForm(searchString: '', limit: 20),
      ).thenThrow(dioError('No access')),
      build: () => WebsiteFormBloc(restClient),
      act: (bloc) => bloc.add(const WebsiteFormFetch()),
      expect: () => [
        formState(WebsiteFormStatus.loading),
        formState(WebsiteFormStatus.failure, message: 'No access'),
      ],
    );

    blocTest<WebsiteFormBloc, WebsiteFormState>(
      'WebsiteFormUpdate_existing_replacesItInPlace',
      setUp: () => when(
        () => restClient.updateWebsiteForm(
          webForm: quote.copyWith(title: 'Get a quote'),
        ),
      ).thenAnswer((_) async => quote.copyWith(title: 'Get a quote')),
      build: () => WebsiteFormBloc(restClient),
      seed: () => WebsiteFormState(webForms: [contact, quote]),
      act: (bloc) =>
          bloc.add(WebsiteFormUpdate(quote.copyWith(title: 'Get a quote'))),
      expect: () => [
        formState(WebsiteFormStatus.loading),
        formState(
          WebsiteFormStatus.success,
          forms: [
            contact,
            quote.copyWith(title: 'Get a quote'),
          ],
          message: 'form quote updated',
        ),
      ],
    );

    blocTest<WebsiteFormBloc, WebsiteFormState>(
      'WebsiteFormUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createWebsiteForm(
          webForm: WebsiteForm(formName: 'quote'),
        ),
      ).thenAnswer((_) async => quote),
      build: () => WebsiteFormBloc(restClient),
      seed: () => WebsiteFormState(webForms: [contact]),
      act: (bloc) =>
          bloc.add(WebsiteFormUpdate(WebsiteForm(formName: 'quote'))),
      expect: () => [
        formState(WebsiteFormStatus.loading),
        formState(
          WebsiteFormStatus.success,
          forms: [quote, contact],
          message: 'form quote added',
        ),
      ],
    );

    blocTest<WebsiteFormBloc, WebsiteFormState>(
      'WebsiteFormDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteWebsiteForm(webForm: contact),
      ).thenAnswer((_) async {}),
      build: () => WebsiteFormBloc(restClient),
      seed: () => WebsiteFormState(webForms: [contact, quote]),
      act: (bloc) => bloc.add(WebsiteFormDelete(contact)),
      expect: () => [
        formState(WebsiteFormStatus.loading),
        formState(
          WebsiteFormStatus.success,
          forms: [quote],
          message: 'form contact deleted',
        ),
      ],
    );

    blocTest<WebsiteFormBloc, WebsiteFormState>(
      'WebsiteFormDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteWebsiteForm(webForm: contact),
      ).thenThrow(dioError('Form has submissions')),
      build: () => WebsiteFormBloc(restClient),
      seed: () => WebsiteFormState(webForms: [contact]),
      act: (bloc) => bloc.add(WebsiteFormDelete(contact)),
      expect: () => [
        formState(WebsiteFormStatus.loading),
        formState(WebsiteFormStatus.failure, message: 'Form has submissions'),
      ],
    );
  });
}
