import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'assessment_model.dart';

part 'persona_model.g.dart';

/// Marketing Persona model representing a customer avatar
///
/// Supports dual-ID strategy:
/// - personaId: System-wide unique identifier
/// - pseudoId: Tenant-unique, user-facing identifier
@JsonSerializable(explicitToJson: true)
class Persona extends Equatable {
  /// System-wide unique identifier
  final String? personaId;

  /// Tenant-unique identifier (user-facing)
  final String? pseudoId;

  /// Persona name (e.g., "Alex Johnson")
  @JsonKey(defaultValue: 'Unnamed Persona')
  final String name;

  /// Demographics description
  final String? demographics;

  /// Pain points description
  final String? painPoints;

  /// Goals and aspirations
  final String? goals;

  /// Preferred tone of voice for communication
  final String? toneOfVoice;

  /// Timestamp when created
  @NullableTimestampConverter()
  final DateTime? createdDate;

  /// Timestamp when last modified
  @NullableTimestampConverter()
  final DateTime? lastModifiedDate;

  const Persona({
    this.personaId,
    this.pseudoId,
    required this.name,
    this.demographics,
    this.painPoints,
    this.goals,
    this.toneOfVoice,
    this.createdDate,
    this.lastModifiedDate,
  });

  /// Creates a copy of this persona with optionally replaced fields
  Persona copyWith({
    String? personaId,
    String? pseudoId,
    String? name,
    String? demographics,
    String? painPoints,
    String? goals,
    String? toneOfVoice,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
  }) {
    return Persona(
      personaId: personaId ?? this.personaId,
      pseudoId: pseudoId ?? this.pseudoId,
      name: name ?? this.name,
      demographics: demographics ?? this.demographics,
      painPoints: painPoints ?? this.painPoints,
      goals: goals ?? this.goals,
      toneOfVoice: toneOfVoice ?? this.toneOfVoice,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
    );
  }

  /// Converts JSON to Persona object
  factory Persona.fromJson(Map<String, dynamic> json) =>
      _$PersonaFromJson(json['persona'] ?? json);

  /// Converts Persona object to JSON
  Map<String, dynamic> toJson() => _$PersonaToJson(this);

  @override
  List<Object?> get props => [
    personaId,
    pseudoId,
    name,
    demographics,
    painPoints,
    goals,
    toneOfVoice,
    createdDate,
    lastModifiedDate,
  ];

  @override
  bool get stringify => true;
}

/// List wrapper for Persona objects
@JsonSerializable()
class Personas {
  final List<Persona> personas;

  const Personas({required this.personas});

  factory Personas.fromJson(Map<String, dynamic> json) =>
      _$PersonasFromJson(json);
  Map<String, dynamic> toJson() => _$PersonasToJson(this);
}
