import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plotcalc/core/localization/app_localizations.dart';
import '../bloc/language_bloc.dart';
import '../bloc/measurement_unit_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load measurement unit preference when page opens
    context.read<MeasurementUnitBloc>().add(const LoadMeasurementUnitEvent());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        children: [
          // Language Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _LanguageOption(language: localizations.english, languageCode: 'en'),
          _LanguageOption(language: localizations.bengali, languageCode: 'bn'),
          
          const Divider(height: 32),
          
          // Measurement Unit Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations.measurementUnit,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _MeasurementUnitOption(
            unit: InputUnit.meters,
            title: localizations.metersTitle,
            description: localizations.useMetersDescription,
          ),
          _MeasurementUnitOption(
            unit: InputUnit.feet,
            title: localizations.feetTitle,
            description: localizations.useFeetDescription,
          ),
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
    final localizations = AppLocalizations.of(context);
    
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
              SnackBar(
                content: Text('${localizations.languageChangedTo} $language'),
              ),
            );
          },
        );
      },
    );
  }
}

class _MeasurementUnitOption extends StatelessWidget {
  final InputUnit unit;
  final String title;
  final String description;

  const _MeasurementUnitOption({
    required this.unit,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return BlocBuilder<MeasurementUnitBloc, MeasurementUnitState>(
      builder: (context, state) {
        final isSelected = state.unit == unit;

        return ListTile(
          title: Text(title),
          subtitle: Text(description),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
              : const Icon(Icons.circle_outlined),
          onTap: () {
            context.read<MeasurementUnitBloc>().add(
              ChangeMeasurementUnitEvent(unit),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${localizations.measurementUnitChanged} ${unit.displayName}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
