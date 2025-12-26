part of 'language_bloc.dart';

sealed class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object> get props => [];
}

class ChangeLanguageEvent extends LanguageEvent {
  final Locale locale;

  const ChangeLanguageEvent(this.locale);

  @override
  List<Object> get props => [locale];
}

class LoadLanguageEvent extends LanguageEvent {}
