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

import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// Starts a course AI job on the backend and follows it by polling until it
/// is finished. The job runs in the background, it can take minutes.

abstract class CourseAiEvent extends Equatable {
  const CourseAiEvent();
  @override
  List<Object?> get props => [];
}

/// Queue a job: [data] holds jobType plus the job input
class CourseAiStart extends CourseAiEvent {
  final Map<String, dynamic> data;
  const CourseAiStart(this.data);
  @override
  List<Object?> get props => [data];
}

/// Pick up a job that is still running for this course (dialog reopened)
class CourseAiWatch extends CourseAiEvent {
  final String courseId;
  const CourseAiWatch(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

class _CourseAiPoll extends CourseAiEvent {
  const _CourseAiPoll();
}

enum CourseAiStatus { initial, running, success, failure }

class CourseAiState extends Equatable {
  final CourseAiStatus status;
  final CourseAiJob? job;
  final String? message;

  const CourseAiState({
    this.status = CourseAiStatus.initial,
    this.job,
    this.message,
  });

  @override
  List<Object?> get props => [
    status,
    job?.jobId,
    job?.status,
    job?.progressPercent,
    job?.statusMessage,
    message,
  ];
}

class CourseAiBloc extends Bloc<CourseAiEvent, CourseAiState> {
  final RestClient restClient;
  final Duration pollInterval;
  Timer? _timer;

  CourseAiBloc({
    required this.restClient,
    this.pollInterval = const Duration(seconds: 3),
  }) : super(const CourseAiState()) {
    on<CourseAiStart>(_onStart);
    on<CourseAiWatch>(_onWatch);
    on<_CourseAiPoll>(_onPoll);
  }

  Future<void> _onStart(
    CourseAiStart event,
    Emitter<CourseAiState> emit,
  ) async {
    try {
      emit(const CourseAiState(status: CourseAiStatus.running));
      var result = await restClient.createCourseAiJob(data: event.data);
      // a dynamic body can arrive as the raw JSON string
      if (result is String) result = jsonDecode(result);
      final job = CourseAiJob.fromJson(result['courseAiJob']);
      emit(CourseAiState(status: CourseAiStatus.running, job: job));
      _schedulePoll();
    } catch (e) {
      emit(
        CourseAiState(
          status: CourseAiStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onWatch(
    CourseAiWatch event,
    Emitter<CourseAiState> emit,
  ) async {
    try {
      final jobs = await restClient.getCourseAiJobs(courseId: event.courseId);
      final running = jobs.courseAiJobs.where((j) => j.isRunning);
      if (running.isEmpty) return;
      emit(CourseAiState(status: CourseAiStatus.running, job: running.first));
      _schedulePoll();
    } catch (_) {
      // nothing running we can show
    }
  }

  Future<void> _onPoll(_CourseAiPoll event, Emitter<CourseAiState> emit) async {
    final jobId = state.job?.jobId;
    if (jobId == null) return;
    try {
      final jobs = await restClient.getCourseAiJobs(jobId: jobId);
      if (jobs.courseAiJobs.isEmpty) return;
      final job = jobs.courseAiJobs.first;
      if (job.isRunning) {
        emit(CourseAiState(status: CourseAiStatus.running, job: job));
        _schedulePoll();
      } else if (job.status == 'DONE') {
        emit(
          CourseAiState(
            status: CourseAiStatus.success,
            job: job,
            message: job.statusMessage,
          ),
        );
      } else {
        emit(
          CourseAiState(
            status: CourseAiStatus.failure,
            job: job,
            message: job.errorMessage ?? job.statusMessage,
          ),
        );
      }
    } catch (_) {
      // a network hiccup: keep following the job
      _schedulePoll();
    }
  }

  void _schedulePoll() {
    _timer?.cancel();
    _timer = Timer(pollInterval, () {
      if (!isClosed) add(const _CourseAiPoll());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
