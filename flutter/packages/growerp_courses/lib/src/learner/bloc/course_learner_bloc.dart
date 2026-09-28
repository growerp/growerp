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

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

part 'course_learner_event.dart';
part 'course_learner_state.dart';

const _learnerLimit = 50;

/// Admin: the persons following courses, their details and course assignments
class CourseLearnerBloc extends Bloc<CourseLearnerEvent, CourseLearnerState> {
  final RestClient restClient;

  CourseLearnerBloc({required this.restClient})
    : super(const CourseLearnerState()) {
    on<CourseLearnerFetch>(_onFetch, transformer: restartable());
    on<CourseLearnerUpdate>(_onUpdate);
    on<CourseLearnerAssign>(_onAssign);
    on<CourseLearnerUnassign>(_onUnassign);
  }

  Future<void> _onFetch(
    CourseLearnerFetch event,
    Emitter<CourseLearnerState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;
    try {
      emit(state.copyWith(status: CourseLearnerStatus.loading));
      final start = event.refresh ? 0 : state.learners.length;
      final response = await restClient.getCourseLearners(
        search: event.searchString,
        start: start,
        limit: _learnerLimit,
      );
      // the courses to assign from, loaded once
      var courses = state.courses;
      if (courses.isEmpty) {
        courses = (await restClient.listCourses(limit: 999)).courses;
      }
      emit(
        state.copyWith(
          status: CourseLearnerStatus.success,
          learners: event.refresh
              ? response.learners
              : [...state.learners, ...response.learners],
          courses: courses,
          hasReachedMax: response.learners.length < _learnerLimit,
          searchString: event.searchString ?? '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseLearnerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  /// Create or update the person. A new person, or one without a login, gets a
  /// customer login with the email as the username, so they can use the academy.
  Future<void> _onUpdate(
    CourseLearnerUpdate event,
    Emitter<CourseLearnerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseLearnerStatus.loading));
      final learner = event.learner;
      final needsLogin = learner.userId == null || learner.userId!.isEmpty;
      final user = User(
        partyId: learner.partyId,
        firstName: learner.firstName,
        lastName: learner.lastName,
        email: learner.email,
        loginName: needsLogin ? learner.email : null,
        role: learner.partyId == null ? Role.customer : null,
        userGroup: needsLogin ? UserGroup.other : null,
      );
      final result = learner.partyId == null
          ? await restClient.createUser(user: user)
          : await restClient.updateUser(user: user);
      final updated = CourseLearner(
        partyId: result.partyId,
        pseudoId: result.pseudoId,
        userId: result.userId,
        firstName: result.firstName,
        lastName: result.lastName,
        email: result.email,
        courses: learner.courses,
      );
      emit(
        state.copyWith(
          status: CourseLearnerStatus.success,
          learners: _replace(updated),
          selected: updated,
          message: learner.partyId == null
              ? 'learnerAddSuccess'
              : 'learnerUpdateSuccess',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseLearnerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onAssign(
    CourseLearnerAssign event,
    Emitter<CourseLearnerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseLearnerStatus.loading));
      await restClient.addCourseLearner(
        partyId: event.learner.partyId!,
        courseId: event.courseId,
      );
      final course = state.courses.firstWhere(
        (c) => c.courseId == event.courseId,
      );
      final updated = _withCourses(event.learner, [
        ...event.learner.courses,
        CourseLearnerCourse(
          courseId: course.courseId,
          title: course.title,
          paid: course.productId != null && course.productId!.isNotEmpty,
        ),
      ]);
      emit(
        state.copyWith(
          status: CourseLearnerStatus.success,
          learners: _replace(updated),
          selected: updated,
          message: 'learnerCourseAssigned',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseLearnerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onUnassign(
    CourseLearnerUnassign event,
    Emitter<CourseLearnerState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CourseLearnerStatus.loading));
      await restClient.removeCourseLearner(
        partyId: event.learner.partyId!,
        courseId: event.courseId,
      );
      final updated = _withCourses(
        event.learner,
        event.learner.courses
            .where((c) => c.courseId != event.courseId)
            .toList(),
      );
      emit(
        state.copyWith(
          status: CourseLearnerStatus.success,
          learners: _replace(updated),
          selected: updated,
          message: 'learnerCourseRemoved',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CourseLearnerStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  CourseLearner _withCourses(
    CourseLearner learner,
    List<CourseLearnerCourse> courses,
  ) => CourseLearner(
    partyId: learner.partyId,
    pseudoId: learner.pseudoId,
    userId: learner.userId,
    firstName: learner.firstName,
    lastName: learner.lastName,
    email: learner.email,
    courses: courses,
  );

  /// The list with this learner replaced, or added at the top when new
  List<CourseLearner> _replace(CourseLearner learner) {
    final index = state.learners.indexWhere(
      (l) => l.partyId == learner.partyId,
    );
    if (index == -1) return [learner, ...state.learners];
    return List.of(state.learners)..[index] = learner;
  }
}
