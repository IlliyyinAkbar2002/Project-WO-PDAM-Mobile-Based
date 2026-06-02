import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_mobile_pdam/core/common/input_chip/bloc/chip_field_event.dart';
import 'package:project_mobile_pdam/core/common/input_chip/bloc/chip_field_state.dart';

class ChipFieldBloc extends Bloc<ChipFieldEvent, ChipFieldState> {
  ChipFieldBloc() : super(ChipFieldInitial()) {
    on<ChipSubmitted>(_onChipSubmitted);
    on<ChipDeleted>(_onChipDeleted);
    on<SearchChanged>(_onSearchChanged);
    on<SuggestionSelected>(_onSuggestionSelected);
  }

  void _onChipSubmitted(ChipSubmitted event, Emitter<ChipFieldState> emit) {
    if (state is ChipFieldLoaded) {
      final currentState = state as ChipFieldLoaded;
      final updatedUsers = List<String>.from(currentState.users)
        ..add(event.chip);
      emit(
        ChipFieldLoaded(
          users: updatedUsers,
          suggestions: currentState.suggestions,
        ),
      );
    }
  }

  void _onChipDeleted(ChipDeleted event, Emitter<ChipFieldState> emit) {
    if (state is ChipFieldLoaded) {
      final currentState = state as ChipFieldLoaded;
      final updatedUsers = List<String>.from(currentState.users)
        ..remove(event.chip);
      emit(
        ChipFieldLoaded(
          users: updatedUsers,
          suggestions: currentState.suggestions,
        ),
      );
    }
  }

  void _onSearchChanged(
    SearchChanged event,
    Emitter<ChipFieldState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(ChipSubmitted(""));
      return;
    }
  }

  void _onSuggestionSelected(
    SuggestionSelected event,
    Emitter<ChipFieldState> emit,
  ) {
    if (state is ChipFieldLoaded) {
      final currentState = state as ChipFieldLoaded;
      final updatedUsers = List<String>.from(currentState.users)
        ..add(event.suggestion);
      emit(
        ChipFieldLoaded(
          users: updatedUsers,
          suggestions: currentState.suggestions,
        ),
      );
    }
  }
}
