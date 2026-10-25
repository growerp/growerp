import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_courses/growerp_courses.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

TypeMatcher<CourseLearnerState> learnerState(
  CourseLearnerStatus status, {
  String? message,
}) {
  var m = isA<CourseLearnerState>().having((s) => s.status, 'status', status);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  final jane = CourseLearner(
    partyId: 'P1',
    userId: 'U1',
    firstName: 'Jane',
    lastName: 'Roe',
    email: 'jane@x.com',
  );
  final paidCourse = Course(courseId: 'C1', title: 'Flutter', productId: 'PR1');

  setUpAll(() => registerFallbackValue(User()));
  setUp(() => restClient = MockRestClient());

  CourseLearnerBloc build() => CourseLearnerBloc(restClient: restClient);

  group('CourseLearnerFetch', () {
    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerFetch_first_loadsLearnersAndCoursesToAssign',
      setUp: () {
        when(
          () => restClient.getCourseLearners(
            start: 0,
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => CourseLearners(learners: [jane]));
        when(
          () => restClient.listCourses(limit: 999),
        ).thenAnswer((_) async => Courses(courses: [paidCourse]));
      },
      build: build,
      act: (bloc) => bloc.add(const CourseLearnerFetch(refresh: true)),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(CourseLearnerStatus.success)
            .having((s) => s.learners, 'learners', [jane])
            .having((s) => s.courses, 'courses', [paidCourse]),
      ],
    );

    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerFetch_coursesLoaded_doesNotReloadCourses',
      setUp: () => when(
        () =>
            restClient.getCourseLearners(start: 0, limit: any(named: 'limit')),
      ).thenAnswer((_) async => CourseLearners(learners: [jane])),
      build: build,
      seed: () => CourseLearnerState(courses: [paidCourse]),
      act: (bloc) => bloc.add(const CourseLearnerFetch(refresh: true)),
      verify: (_) =>
          verifyNever(() => restClient.listCourses(limit: any(named: 'limit'))),
    );

    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerFetch_restThrowsDio_emitsFailure',
      setUp: () => when(
        () =>
            restClient.getCourseLearners(start: 0, limit: any(named: 'limit')),
      ).thenThrow(dioError('No access')),
      build: build,
      act: (bloc) => bloc.add(const CourseLearnerFetch(refresh: true)),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(CourseLearnerStatus.failure, message: 'No access'),
      ],
    );
  });

  group('CourseLearnerUpdate', () {
    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerUpdate_newPerson_createsCustomerLoginWithEmail',
      setUp: () =>
          when(
            () => restClient.createUser(
              user: any(named: 'user'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async => User(
              partyId: 'P2',
              userId: 'U2',
              firstName: 'Max',
              email: 'max@x.com',
            ),
          ),
      build: build,
      act: (bloc) => bloc.add(
        CourseLearnerUpdate(
          CourseLearner(firstName: 'Max', email: 'max@x.com'),
        ),
      ),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(
          CourseLearnerStatus.success,
          message: 'learnerAddSuccess',
        ).having((s) => s.learners.single.partyId, 'partyId', 'P2'),
      ],
      verify: (_) {
        final user =
            verify(
                  () => restClient.createUser(
                    user: captureAny(named: 'user'),
                    password: any(named: 'password'),
                  ),
                ).captured.single
                as User;
        expect(user.loginName, 'max@x.com');
        expect(user.role, Role.customer);
        expect(user.userGroup, UserGroup.other);
      },
    );

    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerUpdate_existingWithLogin_updatesWithoutLoginFields',
      setUp: () => when(() => restClient.updateUser(user: any(named: 'user')))
          .thenAnswer(
            (_) async => User(partyId: 'P1', userId: 'U1', firstName: 'Janet'),
          ),
      build: build,
      seed: () => CourseLearnerState(learners: [jane]),
      act: (bloc) => bloc.add(CourseLearnerUpdate(jane)),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(
          CourseLearnerStatus.success,
          message: 'learnerUpdateSuccess',
        ).having((s) => s.learners.single.firstName, 'firstName', 'Janet'),
      ],
      verify: (_) {
        final user =
            verify(
                  () => restClient.updateUser(user: captureAny(named: 'user')),
                ).captured.single
                as User;
        expect(user.loginName, isNull);
        expect(user.role, isNull);
      },
    );
  });

  group('CourseLearnerAssign / Unassign', () {
    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerAssign_paidCourse_addsCourseMarkedPaid',
      setUp: () => when(
        () => restClient.addCourseLearner(partyId: 'P1', courseId: 'C1'),
      ).thenAnswer((_) async => '{}'),
      build: build,
      seed: () => CourseLearnerState(learners: [jane], courses: [paidCourse]),
      act: (bloc) => bloc.add(CourseLearnerAssign(jane, 'C1')),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(
          CourseLearnerStatus.success,
          message: 'learnerCourseAssigned',
        ).having(
          (s) =>
              s.learners.single.courses.map((c) => '${c.courseId}:${c.paid}'),
          'courses',
          ['C1:true'],
        ),
      ],
    );

    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerUnassign_course_removesIt',
      setUp: () => when(
        () => restClient.removeCourseLearner(partyId: 'P1', courseId: 'C1'),
      ).thenAnswer((_) async => '{}'),
      build: build,
      act: (bloc) => bloc.add(
        CourseLearnerUnassign(
          CourseLearner(
            partyId: 'P1',
            courses: [CourseLearnerCourse(courseId: 'C1')],
          ),
          'C1',
        ),
      ),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(
          CourseLearnerStatus.success,
          message: 'learnerCourseRemoved',
        ).having((s) => s.selected?.courses, 'courses', isEmpty),
      ],
    );

    blocTest<CourseLearnerBloc, CourseLearnerState>(
      'CourseLearnerAssign_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.addCourseLearner(partyId: 'P1', courseId: 'C1'),
      ).thenThrow(dioError('Already assigned')),
      build: build,
      seed: () => CourseLearnerState(courses: [paidCourse]),
      act: (bloc) => bloc.add(CourseLearnerAssign(jane, 'C1')),
      expect: () => [
        learnerState(CourseLearnerStatus.loading),
        learnerState(CourseLearnerStatus.failure, message: 'Already assigned'),
      ],
    );
  });
}
