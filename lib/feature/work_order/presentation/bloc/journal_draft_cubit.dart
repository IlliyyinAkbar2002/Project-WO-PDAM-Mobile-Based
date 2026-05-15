import 'package:flutter_bloc/flutter_bloc.dart';

class JournalDraft {
  final String description;
  final List<dynamic> images;
  final Map<String, dynamic> formData;

  JournalDraft({
    this.description = '',
    this.images = const [],
    this.formData = const {},
  });
}

class JournalDraftCubit extends Cubit<Map<String, JournalDraft>> {
  JournalDraftCubit() : super({});

  void saveDraft(String key, JournalDraft draft) {
    final newState = Map<String, JournalDraft>.from(state);
    newState[key] = draft;
    emit(newState);
  }

  JournalDraft? getDraft(String key) {
    return state[key];
  }

  void clearDraft(String key) {
    final newState = Map<String, JournalDraft>.from(state);
    newState.remove(key);
    emit(newState);
  }
}
