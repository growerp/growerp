import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'email_sequence_event.dart';
import 'email_sequence_state.dart';

/// BLoC for managing email nurture sequences
class EmailSequenceBloc extends Bloc<EmailSequenceEvent, EmailSequenceState> {
  final RestClient restClient;

  EmailSequenceBloc(this.restClient) : super(const EmailSequenceState()) {
    on<EmailSequenceFetch>(_onEmailSequenceFetch);
    on<EmailSequenceUpdate>(_onEmailSequenceUpdate);
    on<EmailSequenceDelete>(_onEmailSequenceDelete);
  }

  Future<void> _onEmailSequenceFetch(
    EmailSequenceFetch event,
    Emitter<EmailSequenceState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmailSequenceStatus.loading));
      final result = await restClient.getEmailSequence(
        searchString: event.searchString,
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: EmailSequenceStatus.success,
          emailSequences: result.emailSequences,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: EmailSequenceStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onEmailSequenceUpdate(
    EmailSequenceUpdate event,
    Emitter<EmailSequenceState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmailSequenceStatus.loading));
      List<EmailSequence> emailSequences = List.from(state.emailSequences);
      if (event.emailSequence.emailSequenceId.isNotEmpty) {
        final result = await restClient.updateEmailSequence(
          emailSequence: event.emailSequence,
        );
        int index = emailSequences.indexWhere(
          (element) =>
              element.emailSequenceId == event.emailSequence.emailSequenceId,
        );
        emailSequences[index] = result;
        emit(
          state.copyWith(
            status: EmailSequenceStatus.success,
            emailSequences: emailSequences,
            message: 'sequence ${event.emailSequence.sequenceName} updated',
          ),
        );
      } else {
        final result = await restClient.createEmailSequence(
          emailSequence: event.emailSequence,
        );
        emailSequences.insert(0, result);
        emit(
          state.copyWith(
            status: EmailSequenceStatus.success,
            emailSequences: emailSequences,
            message: 'sequence ${event.emailSequence.sequenceName} added',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: EmailSequenceStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }

  Future<void> _onEmailSequenceDelete(
    EmailSequenceDelete event,
    Emitter<EmailSequenceState> emit,
  ) async {
    try {
      emit(state.copyWith(status: EmailSequenceStatus.loading));
      List<EmailSequence> emailSequences = List.from(state.emailSequences);
      await restClient.deleteEmailSequence(emailSequence: event.emailSequence);
      emailSequences.removeWhere(
        (element) =>
            element.emailSequenceId == event.emailSequence.emailSequenceId,
      );
      emit(
        state.copyWith(
          status: EmailSequenceStatus.success,
          emailSequences: emailSequences,
          message: 'sequence ${event.emailSequence.sequenceName} deleted',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: EmailSequenceStatus.failure,
          message: await getDioError(e),
        ),
      );
    }
  }
}
