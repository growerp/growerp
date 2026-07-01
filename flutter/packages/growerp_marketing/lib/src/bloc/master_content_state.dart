import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Status enum for MasterContent operations
enum MasterContentStatus {
  initial,
  loading,
  success,
  failure,
}

/// State class for MasterContentBloc
class MasterContentState extends Equatable {
  final MasterContentStatus status;
  final List<MasterContent> masterContents;
  final String? message;
  final bool hasReachedMax;

  /// Result map from the last adapt#ContentForPlatform call
  /// (platform -> outcome string).
  final Map<String, dynamic>? adaptResults;

  const MasterContentState({
    this.status = MasterContentStatus.initial,
    this.masterContents = const [],
    this.message,
    this.hasReachedMax = false,
    this.adaptResults,
  });

  MasterContentState copyWith({
    MasterContentStatus? status,
    List<MasterContent>? masterContents,
    String? message,
    bool? hasReachedMax,
    Map<String, dynamic>? adaptResults,
  }) {
    return MasterContentState(
      status: status ?? this.status,
      masterContents: masterContents ?? this.masterContents,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      adaptResults: adaptResults ?? this.adaptResults,
    );
  }

  @override
  List<Object?> get props =>
      [status, masterContents, message, hasReachedMax, adaptResults];

  @override
  String toString() {
    return 'MasterContentState { status: $status, hasReachedMax: $hasReachedMax, '
        'masterContents: ${masterContents.length}, message: $message }';
  }
}
