import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum EmailSequenceStatus { initial, loading, success, failure }

class EmailSequenceState extends Equatable {
  const EmailSequenceState({
    this.status = EmailSequenceStatus.initial,
    this.emailSequences = const [],
    this.message,
  });

  final EmailSequenceStatus status;
  final List<EmailSequence> emailSequences;
  final String? message;

  EmailSequenceState copyWith({
    EmailSequenceStatus? status,
    List<EmailSequence>? emailSequences,
    String? message,
  }) {
    return EmailSequenceState(
      status: status ?? this.status,
      emailSequences: emailSequences ?? this.emailSequences,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, message, emailSequences];
}
