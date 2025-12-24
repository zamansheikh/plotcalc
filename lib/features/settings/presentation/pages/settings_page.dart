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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        children: [
          // Language Section Header
          Container(
            color: isDarkTheme
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              localizations.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkTheme
                    ? Colors.lightBlue.shade300
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
          _LanguageOption(language: localizations.english, languageCode: 'en'),
          _LanguageOption(language: localizations.bengali, languageCode: 'bn'),

          const Divider(height: 32),

          // Measurement Unit Section Header
          Container(
            color: isDarkTheme
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              localizations.measurementUnit,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkTheme
                    ? Colors.lightBlue.shade300
                    : Theme.of(context).primaryColor,
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

          const SizedBox(height: 24),
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
          title: Text(
            language,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.lightGreen.shade300
                      : Theme.of(context).primaryColor,
                  size: 24,
                )
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
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.lightGreen.shade300
                      : Theme.of(context).primaryColor,
                  size: 24,
                )
              : Icon(
                  Icons.circle_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade500
                      : Colors.grey.shade400,
                  size: 24,
                ),
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
