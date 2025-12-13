import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'persona_event.dart';
import 'persona_state.dart';

/// BLoC for managing Marketing Personas
class PersonaBloc extends Bloc<PersonaEvent, PersonaState> {
  final RestClient restClient;

  PersonaBloc(this.restClient) : super(const PersonaState()) {
    on<PersonaFetch>(_onPersonaFetch);
    on<PersonaCreate>(_onPersonaCreate);
    on<PersonaUpdate>(_onPersonaUpdate);
    on<PersonaDelete>(_onPersonaDelete);
    on<PersonaGenerateWithAI>(_onPersonaGenerateWithAI);
    on<PersonaSearchRequested>(_onPersonaSearchRequested);
  }

  Future<void> _onPersonaFetch(
    PersonaFetch event,
    Emitter<PersonaState> emit,
  ) async {
    if (state.hasReachedMax && !event.refresh) return;

    try {
      if (event.refresh || state.status == PersonaStatus.initial) {
        emit(state.copyWith(status: PersonaStatus.loading));

        final result = await restClient.getMarketingPersonas(
          start: event.start,
          limit: event.limit,
          searchString: event.searchString,
        );

        final personas = result.personas;

        emit(state.copyWith(
          status: PersonaStatus.success,
          personas: personas,
          hasReachedMax: personas.length < event.limit,
        ));
      } else {
        final result = await restClient.getMarketingPersonas(
          start: state.personas.length,
          limit: event.limit,
          searchString: event.searchString,
        );

        final personas = result.personas;

        emit(state.copyWith(
          status: PersonaStatus.success,
          personas: List.of(state.personas)..addAll(personas),
          hasReachedMax: personas.length < event.limit,
        ));
      }
    } on DioException catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPersonaCreate(
    PersonaCreate event,
    Emitter<PersonaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PersonaStatus.loading));

      final newPersona = await restClient.createMarketingPersona(
        name: event.persona.name,
        pseudoId: event.persona.pseudoId,
        demographics: event.persona.demographics,
        painPoints: event.persona.painPoints,
        goals: event.persona.goals,
        toneOfVoice: event.persona.toneOfVoice,
      );

      final updatedPersonas = List<Persona>.from(state.personas)
        ..insert(0, newPersona);

      emit(state.copyWith(
        status: PersonaStatus.success,
        personas: updatedPersonas,
        message: 'Persona created successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPersonaUpdate(
    PersonaUpdate event,
    Emitter<PersonaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PersonaStatus.loading));

      final updatedPersona = await restClient.updateMarketingPersona(
        personaId: event.persona.personaId!,
        pseudoId: event.persona.pseudoId,
        name: event.persona.name,
        demographics: event.persona.demographics,
        painPoints: event.persona.painPoints,
        goals: event.persona.goals,
        toneOfVoice: event.persona.toneOfVoice,
      );

      final updatedPersonas = state.personas
          .map((p) =>
              p.personaId == event.persona.personaId ? updatedPersona : p)
          .toList();

      emit(state.copyWith(
        status: PersonaStatus.success,
        personas: updatedPersonas,
        message: 'Persona updated successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPersonaDelete(
    PersonaDelete event,
    Emitter<PersonaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PersonaStatus.loading));

      await restClient.deleteMarketingPersona(
        personaId: event.persona.personaId!,
      );

      final updatedPersonas = state.personas
          .where((p) => p.personaId != event.persona.personaId)
          .toList();

      emit(state.copyWith(
        status: PersonaStatus.success,
        personas: updatedPersonas,
        message: 'Persona deleted successfully',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPersonaGenerateWithAI(
    PersonaGenerateWithAI event,
    Emitter<PersonaState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PersonaStatus.loading));

      final generatedPersona = await restClient.generateMarketingPersonaWithAI(
        businessDescription: event.businessDescription,
        targetMarket: event.targetMarket,
      );

      final updatedPersonas = List<Persona>.from(state.personas)
        ..insert(0, generatedPersona);

      emit(state.copyWith(
        status: PersonaStatus.success,
        personas: updatedPersonas,
        message: 'Persona generated successfully with AI',
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PersonaStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onPersonaSearchRequested(
    PersonaSearchRequested event,
    Emitter<PersonaState> emit,
  ) async {
    try {
      emit(state.copyWith(searchStatus: PersonaStatus.loading));

      final result = await restClient.getMarketingPersonas(
        searchString: event.searchString,
        limit: 20, // Default limit for search
      );

      final searchResults = result.personas;

      emit(state.copyWith(
        searchStatus: PersonaStatus.success,
        searchResults: searchResults,
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        searchStatus: PersonaStatus.failure,
        searchError: await getDioError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        searchStatus: PersonaStatus.failure,
        searchError: e.toString(),
      ));
    }
  }
}
