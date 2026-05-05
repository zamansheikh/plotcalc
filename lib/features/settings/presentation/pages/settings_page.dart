import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, loc),
              const SizedBox(height: 24),

              // Language Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionTitle(loc.language),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLanguageCard(loc),
              ),

              const SizedBox(height: 24),

              // Measurement Unit Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionTitle(loc.measurementUnit),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMeasurementUnitCard(loc),
              ),

              const SizedBox(height: 24),

              // About Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionTitle(loc.aboutDeveloper),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildAboutCard(loc),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            loc.settings,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildLanguageCard(AppLocalizations loc) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildOptionTile(
                title: loc.english,
                isSelected: state.locale.languageCode == 'en',
                onTap: () {
                  context.read<LanguageBloc>().add(
                    ChangeLanguageEvent(const Locale('en')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${loc.languageChangedTo} ${loc.english}'),
                    ),
                  );
                },
                isFirst: true,
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildOptionTile(
                title: loc.bengali,
                isSelected: state.locale.languageCode == 'bn',
                onTap: () {
                  context.read<LanguageBloc>().add(
                    ChangeLanguageEvent(const Locale('bn')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${loc.languageChangedTo} ${loc.bengali}'),
                    ),
                  );
                },
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurementUnitCard(AppLocalizations loc) {
    return BlocBuilder<MeasurementUnitBloc, MeasurementUnitState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildOptionTile(
                title: loc.metersTitle,
                subtitle: loc.useMetersDescription,
                isSelected: state.unit == InputUnit.meters,
                onTap: () {
                  context.read<MeasurementUnitBloc>().add(
                    const ChangeMeasurementUnitEvent(InputUnit.meters),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${loc.measurementUnitChanged} ${loc.metersTitle}',
                      ),
                    ),
                  );
                },
                isFirst: true,
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildOptionTile(
                title: loc.feetTitle,
                subtitle: loc.useFeetDescription,
                isSelected: state.unit == InputUnit.feet,
                onTap: () {
                  context.read<MeasurementUnitBloc>().add(
                    const ChangeMeasurementUnitEvent(InputUnit.feet),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${loc.measurementUnitChanged} ${loc.feetTitle}',
                      ),
                    ),
                  );
                },
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 16 : 0),
          topRight: Radius.circular(isFirst ? 16 : 0),
          bottomLeft: Radius.circular(isLast ? 16 : 0),
          bottomRight: Radius.circular(isLast ? 16 : 0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(AppLocalizations loc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showDeveloperInfoDialog,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF546E7A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 24,
                  color: Color(0xFF546E7A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.aboutDeveloper,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.appInfoContact,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeveloperInfoDialog() {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 36,
                backgroundImage: AssetImage('assets/icon/icon.png'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Md. Shamsuzzaman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              loc.fullStackDeveloper,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildSocialLink(
              icon: Icons.code_rounded,
              label: 'GitHub',
              value: 'github.com/zamansheikh',
              url: 'https://github.com/zamansheikh',
            ),
            const SizedBox(height: 10),
            _buildSocialLink(
              icon: Icons.facebook_rounded,
              label: 'Facebook',
              value: 'facebook.com/zamansheikh.404',
              url: 'https://facebook.com/zamansheikh.404',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
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
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1A1A1A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
