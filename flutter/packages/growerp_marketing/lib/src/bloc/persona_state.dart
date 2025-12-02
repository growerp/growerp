import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Status enum for Persona operations
enum PersonaStatus {
  initial,
  loading,
  success,
  failure,
}

/// State class for PersonaBloc
class PersonaState extends Equatable {
  final PersonaStatus status;
  final List<Persona> personas;
  final String? message;
  final bool hasReachedMax;

  final List<Persona> searchResults;
  final PersonaStatus searchStatus;
  final String? searchError;

  const PersonaState({
    this.status = PersonaStatus.initial,
    this.personas = const [],
    this.message,
    this.hasReachedMax = false,
    this.searchResults = const [],
    this.searchStatus = PersonaStatus.initial,
    this.searchError,
  });

  PersonaState copyWith({
    PersonaStatus? status,
    List<Persona>? personas,
    String? message,
    bool? hasReachedMax,
    List<Persona>? searchResults,
    PersonaStatus? searchStatus,
    String? searchError,
  }) {
    return PersonaState(
      status: status ?? this.status,
      personas: personas ?? this.personas,
      message: message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchResults: searchResults ?? this.searchResults,
      searchStatus: searchStatus ?? this.searchStatus,
      searchError: searchError ?? this.searchError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        personas,
        message,
        hasReachedMax,
        searchResults,
        searchStatus,
        searchError,
      ];

  @override
  String toString() {
    return 'PersonaState { status: $status, hasReachedMax: $hasReachedMax, '
        'personas: ${personas.length}, message: $message, '
        'searchResults: ${searchResults.length}, searchStatus: $searchStatus }';
  }
}
