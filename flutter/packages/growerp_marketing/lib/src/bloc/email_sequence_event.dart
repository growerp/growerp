import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

abstract class EmailSequenceEvent extends Equatable {
  const EmailSequenceEvent();
  @override
  List<Object> get props => [];
}

class EmailSequenceFetch extends EmailSequenceEvent {
  const EmailSequenceFetch({this.searchString = '', this.limit = 20});
  final String searchString;
  final int limit;
  @override
  List<Object> get props => [searchString];
}

class EmailSequenceUpdate extends EmailSequenceEvent {
  const EmailSequenceUpdate(this.emailSequence);
  final EmailSequence emailSequence;
}

class EmailSequenceDelete extends EmailSequenceEvent {
  const EmailSequenceDelete(this.emailSequence);
  final EmailSequence emailSequence;
}

class EmailSequenceMembersFetch extends EmailSequenceEvent {
  const EmailSequenceMembersFetch(this.emailSequenceId, {this.searchString = ''});
  final String emailSequenceId;
  final String searchString;
  @override
  List<Object> get props => [emailSequenceId, searchString];
}

class EmailSequenceMemberAdd extends EmailSequenceEvent {
  const EmailSequenceMemberAdd({
    required this.emailSequenceId,
    required this.emailAddress,
    this.firstName,
  });
  final String emailSequenceId;
  final String emailAddress;
  final String? firstName;
}

class EmailSequenceMemberUnsubscribe extends EmailSequenceEvent {
  const EmailSequenceMemberUnsubscribe({
    required this.emailSequenceId,
    required this.enrollmentId,
  });
  final String emailSequenceId;
  final String enrollmentId;
}
