import 'package:equatable/equatable.dart';
import 'package:growerp_models/growerp_models.dart';

/// Base class for all Persona events
abstract class PersonaEvent extends Equatable {
  const PersonaEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch personas (with optional refresh and search)
class PersonaFetch extends PersonaEvent {
  final bool refresh;
  final int limit;
  final int start;
  final String searchString;

  const PersonaFetch({
    this.refresh = false,
    this.limit = 20,
    this.start = 0,
    this.searchString = '',
  });

  @override
  List<Object?> get props => [refresh, limit, start, searchString];
}

/// Event to create a new persona
class PersonaCreate extends PersonaEvent {
  final Persona persona;

  const PersonaCreate(this.persona);

  @override
  List<Object?> get props => [persona];
}

/// Event to update an existing persona
class PersonaUpdate extends PersonaEvent {
  final Persona persona;

  const PersonaUpdate(this.persona);

  @override
  List<Object?> get props => [persona];
}

/// Event to delete a persona
class PersonaDelete extends PersonaEvent {
  final Persona persona;

  const PersonaDelete(this.persona);

  @override
  List<Object?> get props => [persona];
}

/// Event to generate a persona using AI
class PersonaGenerateWithAI extends PersonaEvent {
  final String businessDescription;
  final String? targetMarket;

  const PersonaGenerateWithAI({
    required this.businessDescription,
    this.targetMarket,
  });

  @override
  List<Object?> get props => [businessDescription, targetMarket];
}

class PersonaSearchRequested extends PersonaEvent {
  final String searchString;

  const PersonaSearchRequested({required this.searchString});

  @override
  List<Object> get props => [searchString];
}
