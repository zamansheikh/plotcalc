import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'language_event.dart';
part 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _key = 'language_preference';

  LanguageBloc() : super(const LanguageState(locale: Locale('en'))) {
    on<LoadLanguageEvent>(_onLoadLanguage);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
    LoadLanguageEvent event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_key);
      if (languageCode != null) {
        emit(LanguageState(locale: Locale(languageCode)));
      } else {
        // If no preference, use device locale if supported, otherwise default to English
        final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        if (deviceLocale.languageCode == 'bn') {
          emit(const LanguageState(locale: Locale('bn')));
        } else {
          emit(const LanguageState(locale: Locale('en')));
        }
      }
    } catch (e) {
      debugPrint('Error loading language preference: $e');
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguageEvent event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, event.locale.languageCode);
      emit(LanguageState(locale: event.locale));
    } catch (e) {
      debugPrint('Error saving language preference: $e');
      emit(LanguageState(locale: event.locale));
    }
  }
}
