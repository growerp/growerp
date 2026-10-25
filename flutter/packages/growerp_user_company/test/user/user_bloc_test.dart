import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_user_company/growerp_user_company.dart';
import 'package:mocktail/mocktail.dart';

import '../shared/mocks.dart';

// UserFetch is throttled 100ms, UserSearchChanged debounced.
const fetchWait = Duration(milliseconds: 150);

TypeMatcher<UserState> userState(UserStatus status, {List<User>? users, String? message}) {
  var m = isA<UserState>().having((s) => s.status, 'status', status);
  if (users != null) m = m.having((s) => s.users, 'users', users);
  if (message != null) m = m.having((s) => s.message, 'message', message);
  return m;
}

void main() {
  late MockRestClient restClient;

  setUp(() => restClient = MockRestClient());

  group('UserFetch', () {
    blocTest<UserBloc, UserState>(
      'UserFetch_initial_requestsRoleAndEmitsFirstPage',
      setUp: () => when(
        () => restClient.getUser(
          start: 0,
          limit: 20,
          role: Role.customer,
          searchString: '',
        ),
      ).thenAnswer((_) async => Users(users: [user1, user2])),
      build: () => UserBloc(restClient, Role.customer),
      act: (bloc) => bloc.add(const UserFetch()),
      wait: fetchWait,
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.success, users: [user1, user2])
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserFetch_nextPage_appendsFromCurrentLength',
      setUp: () => when(
        () => restClient.getUser(
          start: 1,
          limit: 1,
          role: Role.customer,
          searchString: '',
        ),
      ).thenAnswer((_) async => Users(users: [user2])),
      build: () => UserBloc(restClient, Role.customer),
      seed: () => UserState(status: UserStatus.success, users: [user1]),
      act: (bloc) => bloc.add(const UserFetch(limit: 1)),
      wait: fetchWait,
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.success, users: [user1, user2])
            .having((s) => s.hasReachedMax, 'hasReachedMax', false),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserFetch_restThrowsDio_emitsFailureAndClearsList',
      setUp: () => when(
        () => restClient.getUser(
          start: 0,
          limit: 20,
          role: Role.customer,
          searchString: '',
        ),
      ).thenThrow(dioError('User service down')),
      build: () => UserBloc(restClient, Role.customer),
      act: (bloc) => bloc.add(const UserFetch()),
      wait: fetchWait,
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.failure, users: [], message: 'User service down'),
      ],
    );
  });

  group('UserSearchChanged', () {
    blocTest<UserBloc, UserState>(
      'UserSearchChanged_threeChars_fetchesFirstPageWithSearch',
      setUp: () => when(
        () => restClient.getUser(
          start: 0,
          limit: 20,
          role: Role.customer,
          searchString: 'Joh',
        ),
      ).thenAnswer((_) async => Users(users: [user1])),
      build: () => UserBloc(restClient, Role.customer),
      seed: () => UserState(status: UserStatus.success, users: [user1, user2]),
      act: (bloc) => bloc.add(const UserSearchChanged(searchString: 'Joh')),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.success, users: [user1]),
      ],
    );
  });

  group('UserUpdate', () {
    final changed = user2.copyWith(lastName: 'Smith');
    final newUser = User(firstName: 'Max', lastName: 'Mustermann');
    final created = newUser.copyWith(partyId: 'U3');

    blocTest<UserBloc, UserState>(
      'UserUpdate_existingUser_movesUpdatedUserToTop',
      setUp: () => when(
        () => restClient.updateUser(user: changed),
      ).thenAnswer((_) async => changed),
      build: () => UserBloc(restClient, Role.customer),
      seed: () => UserState(status: UserStatus.success, users: [user1, user2]),
      act: (bloc) => bloc.add(UserUpdate(changed)),
      expect: () => [
        userState(UserStatus.loading),
        userState(
          UserStatus.success,
          users: [changed, user1],
          message: 'userUpdateSuccess:Jane Smith',
        ),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserUpdate_existingUserEmptyList_addsIt',
      setUp: () => when(
        () => restClient.updateUser(user: changed),
      ).thenAnswer((_) async => changed),
      build: () => UserBloc(restClient, Role.customer),
      act: (bloc) => bloc.add(UserUpdate(changed)),
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.success, users: [changed]),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserUpdate_newUser_createsAndInsertsFirst',
      setUp: () => when(
        () => restClient.createUser(user: newUser),
      ).thenAnswer((_) async => created),
      build: () => UserBloc(restClient, Role.customer),
      seed: () => UserState(status: UserStatus.success, users: [user1]),
      act: (bloc) => bloc.add(UserUpdate(newUser)),
      expect: () => [
        userState(UserStatus.loading),
        userState(
          UserStatus.success,
          users: [created, user1],
          message: 'userAddSuccess:Max Mustermann',
        ),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserUpdate_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.createUser(user: newUser),
      ).thenThrow(dioError('Email already in use')),
      build: () => UserBloc(restClient, Role.customer),
      act: (bloc) => bloc.add(UserUpdate(newUser)),
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.failure, message: 'Email already in use'),
      ],
    );
  });

  group('UserDelete', () {
    blocTest<UserBloc, UserState>(
      'UserDelete_existingUser_keepsCompanyAndRemovesUser',
      setUp: () => when(
        () => restClient.deleteUser(partyId: 'U1', deleteCompanyToo: false),
      ).thenAnswer((_) async => user1),
      build: () => UserBloc(restClient, Role.customer),
      seed: () => UserState(status: UserStatus.success, users: [user1, user2]),
      act: (bloc) => bloc.add(UserDelete(user1)),
      expect: () => [
        userState(UserStatus.loading),
        userState(
          UserStatus.success,
          users: [user2],
          message: 'userDeleteSuccess:John Doe',
        ),
      ],
    );

    blocTest<UserBloc, UserState>(
      'UserDelete_restThrowsDio_emitsFailure',
      setUp: () => when(
        () => restClient.deleteUser(partyId: 'U1', deleteCompanyToo: false),
      ).thenThrow(dioError('User has orders')),
      build: () => UserBloc(restClient, Role.customer),
      seed: () => UserState(status: UserStatus.success, users: [user1]),
      act: (bloc) => bloc.add(UserDelete(user1)),
      expect: () => [
        userState(UserStatus.loading),
        userState(UserStatus.failure, message: 'User has orders'),
      ],
    );
  });
}
