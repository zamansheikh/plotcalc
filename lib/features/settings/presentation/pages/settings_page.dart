import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
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

          const Divider(height: 32),

          // About Section
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Developer'),
            subtitle: const Text('App info & developer contact'),
            onTap: _showDeveloperInfoDialog,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDeveloperInfoDialog() {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(
                'assets/icon/icon.png',
              ), // Fallback or app icon
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Md. Shamsuzzaman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Full Stack Developer',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildSocialLink(
              icon: Icons.code,
              label: 'GitHub',
              value: 'github.com/zamansheikh',
              url: 'https://github.com/zamansheikh',
              isDark: isDarkTheme,
            ),
            const SizedBox(height: 12),
            _buildSocialLink(
              icon: Icons.facebook,
              label: 'Facebook',
              value: 'facebook.com/zamansheikh.404',
              url: 'https://facebook.com/zamansheikh.404',
              isDark: isDarkTheme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLink({
    required IconData icon,
    required String label,
    required String value,
    required String url,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ],
        ),
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
