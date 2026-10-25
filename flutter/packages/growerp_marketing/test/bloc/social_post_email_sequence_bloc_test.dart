import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_marketing/growerp_marketing.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('SocialPostBloc', () {
    const draft = SocialPost(
      postId: 'S1',
      type: 'PAS',
      status: 'DRAFT',
      headline: 'Pain',
    );
    const scheduled = SocialPost(
      postId: 'S2',
      type: 'AIDA',
      status: 'SCHEDULED',
    );

    TypeMatcher<SocialPostState> postState(
      SocialPostStatus status, {
      List<SocialPost>? posts,
      String? message,
    }) {
      var m = isA<SocialPostState>().having((s) => s.status, 'status', status);
      if (posts != null) m = m.having((s) => s.socialPosts, 'posts', posts);
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    SocialPostBloc build() => SocialPostBloc(restClient);

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostFetch_plan_loadsPostsOfThatPlan',
      setUp: () =>
          when(
            () => restClient.getSocialPosts(
              start: 0,
              limit: 20,
              searchString: '',
              planId: 'CP1',
            ),
          ).thenAnswer(
            (_) async => const SocialPosts(socialPosts: [draft, scheduled]),
          ),
      build: build,
      act: (bloc) => bloc.add(const SocialPostFetch(planId: 'CP1')),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(SocialPostStatus.success, posts: [draft, scheduled]),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.getSocialPosts(start: 0, limit: 20, searchString: ''),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const SocialPostFetch()),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(SocialPostStatus.failure, message: 'No access'),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostCreate_scheduled_sendsEpochAndInsertsFirst',
      setUp: () => when(
        () => restClient.createSocialPost(
          type: 'AIDA',
          status: 'SCHEDULED',
          scheduledDate: DateTime.utc(2026, 11, 1, 9).millisecondsSinceEpoch,
        ),
      ).thenAnswer((_) async => scheduled),
      build: build,
      seed: () => const SocialPostState(socialPosts: [draft]),
      act: (bloc) => bloc.add(
        SocialPostCreate(
          SocialPost(
            type: 'AIDA',
            status: 'SCHEDULED',
            scheduledDate: DateTime.utc(2026, 11, 1, 9),
          ),
        ),
      ),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(SocialPostStatus.success, posts: [scheduled, draft]),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostUpdate_existing_replacesIt',
      setUp: () =>
          when(
            () => restClient.updateSocialPost(
              postId: 'S1',
              type: 'PAS',
              status: 'DRAFT',
              headline: 'Pain point',
            ),
          ).thenAnswer(
            (_) async => const SocialPost(
              postId: 'S1',
              type: 'PAS',
              status: 'DRAFT',
              headline: 'Pain point',
            ),
          ),
      build: build,
      seed: () => const SocialPostState(socialPosts: [draft, scheduled]),
      act: (bloc) => bloc.add(
        const SocialPostUpdate(
          SocialPost(
            postId: 'S1',
            type: 'PAS',
            status: 'DRAFT',
            headline: 'Pain point',
          ),
        ),
      ),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(
          SocialPostStatus.success,
        ).having((s) => s.socialPosts.first.headline, 'headline', 'Pain point'),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteSocialPost(postId: 'S1'),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => const SocialPostState(socialPosts: [draft, scheduled]),
      act: (bloc) => bloc.add(const SocialPostDelete(draft)),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(SocialPostStatus.success, posts: [scheduled]),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostDraftWithAI_post_replacesWithDraft',
      setUp: () =>
          when(() => restClient.draftSocialPostWithAI(postId: 'S1')).thenAnswer(
            (_) async => const SocialPost(
              postId: 'S1',
              type: 'PAS',
              status: 'DRAFT',
              draftContent: 'AI text',
            ),
          ),
      build: build,
      seed: () => const SocialPostState(socialPosts: [draft, scheduled]),
      act: (bloc) => bloc.add(const SocialPostDraftWithAI(postId: 'S1')),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(
          SocialPostStatus.success,
        ).having((s) => s.socialPosts.first.draftContent, 'draft', 'AI text'),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostPublish_post_replacesWithPublished',
      setUp: () =>
          when(() => restClient.publishSocialPost(postId: 'S2')).thenAnswer(
            (_) async => const SocialPost(
              postId: 'S2',
              type: 'AIDA',
              status: 'PUBLISHED',
            ),
          ),
      build: build,
      seed: () => const SocialPostState(socialPosts: [draft, scheduled]),
      act: (bloc) => bloc.add(const SocialPostPublish(postId: 'S2')),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(
          SocialPostStatus.success,
          message: 'Post published successfully',
        ).having((s) => s.socialPosts.last.status, 'status', 'PUBLISHED'),
      ],
    );

    blocTest<SocialPostBloc, SocialPostState>(
      'SocialPostPublish_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.publishSocialPost(postId: 'S2'),
      ).thenThrow(dioError('LinkedIn token expired')),
      build: build,
      act: (bloc) => bloc.add(const SocialPostPublish(postId: 'S2')),
      expect: () => [
        postState(SocialPostStatus.loading),
        postState(SocialPostStatus.failure, message: 'LinkedIn token expired'),
      ],
    );
  });

  group('EmailSequenceBloc', () {
    final welcome = EmailSequence(
      emailSequenceId: 'Q1',
      sequenceName: 'welcome',
    );
    final nurture = EmailSequence(
      emailSequenceId: 'Q2',
      sequenceName: 'nurture',
    );
    final jane = EmailSequenceEnrollment(
      enrollmentId: 'N1',
      emailAddress: 'jane@x.com',
    );

    TypeMatcher<EmailSequenceState> seqState(
      EmailSequenceStatus status, {
      List<EmailSequence>? sequences,
      String? message,
    }) {
      var m = isA<EmailSequenceState>().having(
        (s) => s.status,
        'status',
        status,
      );
      if (sequences != null) {
        m = m.having((s) => s.emailSequences, 'sequences', sequences);
      }
      if (message != null) m = m.having((s) => s.message, 'message', message);
      return m;
    }

    EmailSequenceBloc build() => EmailSequenceBloc(restClient);

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceFetch_search_setsSequences',
      setUp: () => when(
        () => restClient.getEmailSequence(searchString: 'wel', limit: 20),
      ).thenAnswer((_) async => EmailSequences(emailSequences: [welcome])),
      build: build,
      act: (bloc) => bloc.add(const EmailSequenceFetch(searchString: 'wel')),
      expect: () => [
        seqState(EmailSequenceStatus.loading),
        seqState(EmailSequenceStatus.success, sequences: [welcome]),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceUpdate_new_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createEmailSequence(
          emailSequence: EmailSequence(sequenceName: 'nurture'),
        ),
      ).thenAnswer((_) async => nurture),
      build: build,
      seed: () => EmailSequenceState(emailSequences: [welcome]),
      act: (bloc) =>
          bloc.add(EmailSequenceUpdate(EmailSequence(sequenceName: 'nurture'))),
      expect: () => [
        seqState(EmailSequenceStatus.loading),
        seqState(
          EmailSequenceStatus.success,
          sequences: [nurture, welcome],
          message: 'sequence nurture added',
        ),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceUpdate_existing_replacesIt',
      setUp: () => when(
        () => restClient.updateEmailSequence(
          emailSequence: welcome.copyWith(status: 'PAUSED'),
        ),
      ).thenAnswer((_) async => welcome.copyWith(status: 'PAUSED')),
      build: build,
      seed: () => EmailSequenceState(emailSequences: [welcome, nurture]),
      act: (bloc) =>
          bloc.add(EmailSequenceUpdate(welcome.copyWith(status: 'PAUSED'))),
      expect: () => [
        seqState(EmailSequenceStatus.loading),
        seqState(
          EmailSequenceStatus.success,
          sequences: [
            welcome.copyWith(status: 'PAUSED'),
            nurture,
          ],
          message: 'sequence welcome updated',
        ),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceDelete_existing_removesIt',
      setUp: () => when(
        () => restClient.deleteEmailSequence(emailSequence: welcome),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => EmailSequenceState(emailSequences: [welcome, nurture]),
      act: (bloc) => bloc.add(EmailSequenceDelete(welcome)),
      expect: () => [
        seqState(EmailSequenceStatus.loading),
        seqState(EmailSequenceStatus.success, sequences: [nurture]),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteEmailSequence(emailSequence: welcome),
      ).thenThrow(dioError('Has members')),
      build: build,
      act: (bloc) => bloc.add(EmailSequenceDelete(welcome)),
      expect: () => [
        seqState(EmailSequenceStatus.loading),
        seqState(EmailSequenceStatus.failure, message: 'Has members'),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceMembersFetch_sequence_usesMemberStatusOnly',
      setUp: () => when(
        () => restClient.getEmailSequenceEnrollments(
          emailSequenceId: 'Q1',
          searchString: '',
        ),
      ).thenAnswer((_) async => EmailSequenceEnrollments(enrollments: [jane])),
      build: build,
      act: (bloc) => bloc.add(const EmailSequenceMembersFetch('Q1')),
      expect: () => [
        isA<EmailSequenceState>()
            .having(
              (s) => s.memberStatus,
              'memberStatus',
              EmailSequenceStatus.loading,
            )
            .having((s) => s.status, 'status', EmailSequenceStatus.initial),
        isA<EmailSequenceState>()
            .having(
              (s) => s.memberStatus,
              'memberStatus',
              EmailSequenceStatus.success,
            )
            .having((s) => s.members, 'members', [jane]),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceMemberAdd_email_addsAndReloadsMembers',
      setUp: () {
        when(
          () => restClient.addEmailSequenceMember(
            emailSequenceId: 'Q1',
            emailAddress: 'jane@x.com',
            firstName: 'Jane',
          ),
        ).thenAnswer((_) async {});
        when(
          () => restClient.getEmailSequenceEnrollments(emailSequenceId: 'Q1'),
        ).thenAnswer(
          (_) async => EmailSequenceEnrollments(enrollments: [jane]),
        );
      },
      build: build,
      act: (bloc) => bloc.add(
        const EmailSequenceMemberAdd(
          emailSequenceId: 'Q1',
          emailAddress: 'jane@x.com',
          firstName: 'Jane',
        ),
      ),
      expect: () => [
        isA<EmailSequenceState>(),
        isA<EmailSequenceState>()
            .having((s) => s.members, 'members', [jane])
            .having(
              (s) => s.memberMessage,
              'memberMessage',
              'jane@x.com added',
            ),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceMemberUnsubscribe_member_unsubscribesAndReloads',
      setUp: () {
        when(
          () => restClient.unsubscribeEmailSequenceMember(
            emailSequenceId: 'Q1',
            enrollmentId: 'N1',
          ),
        ).thenAnswer((_) async {});
        when(
          () => restClient.getEmailSequenceEnrollments(emailSequenceId: 'Q1'),
        ).thenAnswer((_) async => EmailSequenceEnrollments());
      },
      build: build,
      seed: () => EmailSequenceState(members: [jane]),
      act: (bloc) => bloc.add(
        const EmailSequenceMemberUnsubscribe(
          emailSequenceId: 'Q1',
          enrollmentId: 'N1',
        ),
      ),
      expect: () => [
        isA<EmailSequenceState>(),
        isA<EmailSequenceState>()
            .having((s) => s.members, 'members', isEmpty)
            .having(
              (s) => s.memberMessage,
              'memberMessage',
              'member unsubscribed',
            ),
      ],
    );

    blocTest<EmailSequenceBloc, EmailSequenceState>(
      'EmailSequenceMemberAdd_restThrowsDio_setsMemberFailure',
      setUp: () => when(
        () => restClient.addEmailSequenceMember(
          emailSequenceId: 'Q1',
          emailAddress: 'bad',
        ),
      ).thenThrow(dioError('Invalid email')),
      build: build,
      act: (bloc) => bloc.add(
        const EmailSequenceMemberAdd(
          emailSequenceId: 'Q1',
          emailAddress: 'bad',
        ),
      ),
      expect: () => [
        isA<EmailSequenceState>(),
        isA<EmailSequenceState>()
            .having(
              (s) => s.memberStatus,
              'memberStatus',
              EmailSequenceStatus.failure,
            )
            .having((s) => s.memberMessage, 'memberMessage', 'Invalid email'),
      ],
    );
  });
}
