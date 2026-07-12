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
