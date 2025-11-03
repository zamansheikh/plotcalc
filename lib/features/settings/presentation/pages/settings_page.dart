import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../bloc/language_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _LanguageOption(language: localizations.english, languageCode: 'en'),
          _LanguageOption(language: localizations.bengali, languageCode: 'bn'),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String language;
  final String languageCode;

  const _LanguageOption({required this.language, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final isSelected = state.locale.languageCode == languageCode;

        return ListTile(
          title: Text(language),
          trailing: isSelected
              ? Icon(Icons.check, color: Theme.of(context).primaryColor)
              : null,
          onTap: () {
            context.read<LanguageBloc>().add(
              ChangeLanguageEvent(Locale(languageCode)),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Language changed to $language')),
            );
          },
        );
      },
    );
  }
}
