import 'dart:async';
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

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final List<String> results = await _suggestionCallback(event.query);
      if (state is ChipFieldLoaded) {
        final currentState = state as ChipFieldLoaded;
        final suggestions = results
            .where((String user) => !currentState.users.contains(user))
            .toList();
        emit(
          ChipFieldLoaded(users: currentState.users, suggestions: suggestions),
        );
      }
    });
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

  FutureOr<List<String>> _suggestionCallback(String text) {
    if (text.isNotEmpty) {
      return _user.where((String user) {
        return user.toLowerCase().contains(text.toLowerCase());
      }).toList();
    }
    return const <String>[];
  }

  Timer? _debounce;
}

const List<String> _user = <String>[
  'Raihan',
  'Dukhaan',
  'Fatimah',
  'Salsa',
  'Yusuf',
  'Rahman',
  'Rahim',
  'Siti',
  'Nur',
  'Aisyah',
];
