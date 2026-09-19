import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

enum EmailSequenceStatus { initial, loading, success, failure }

class EmailSequenceState extends Equatable {
  const EmailSequenceState({
    this.status = EmailSequenceStatus.initial,
    this.emailSequences = const [],
    this.message,
    this.memberStatus = EmailSequenceStatus.initial,
    this.members = const [],
    this.memberMessage,
  });

  final EmailSequenceStatus status;
  final List<EmailSequence> emailSequences;
  final String? message;
  final EmailSequenceStatus memberStatus;
  final List<EmailSequenceEnrollment> members;
  final String? memberMessage;

  EmailSequenceState copyWith({
    EmailSequenceStatus? status,
    List<EmailSequence>? emailSequences,
    String? message,
    EmailSequenceStatus? memberStatus,
    List<EmailSequenceEnrollment>? members,
    String? memberMessage,
  }) {
    return EmailSequenceState(
      status: status ?? this.status,
      emailSequences: emailSequences ?? this.emailSequences,
      message: message,
      memberStatus: memberStatus ?? this.memberStatus,
      members: members ?? this.members,
      memberMessage: memberMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    emailSequences,
    memberStatus,
    memberMessage,
    members,
  ];
}
