import 'dart:typed_data';
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

  /// The ZIP from the last export, to be saved by the files dialog; only set
  /// on the state the export emits.
  final ({String name, Uint8List bytes})? exportFile;

  const MasterContentState({
    this.status = MasterContentStatus.initial,
    this.masterContents = const [],
    this.message,
    this.hasReachedMax = false,
    this.adaptResults,
    this.exportFile,
  });

  MasterContentState copyWith({
    MasterContentStatus? status,
    List<MasterContent>? masterContents,
    String? message,
    bool? hasReachedMax,
    Map<String, dynamic>? adaptResults,
    ({String name, Uint8List bytes})? exportFile,
  }) {
    return MasterContentState(
      status: status ?? this.status,
      masterContents: masterContents ?? this.masterContents,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      adaptResults: adaptResults ?? this.adaptResults,
      exportFile: exportFile,
    );
  }

  @override
  List<Object?> get props =>
      [status, masterContents, message, hasReachedMax, adaptResults, exportFile];

  @override
  String toString() {
    return 'MasterContentState { status: $status, hasReachedMax: $hasReachedMax, '
        'masterContents: ${masterContents.length}, message: $message }';
  }
}
