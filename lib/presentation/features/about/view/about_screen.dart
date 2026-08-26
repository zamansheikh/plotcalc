import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../../../../l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  /// Read from the installed package rather than written down here, so it
  /// cannot drift from pubspec the way the hardcoded "1.0.0" had.
  PackageInfo? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _Header(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _HeroCard(accent: accent, version: _version),
                  const SizedBox(height: 14),
                  _Section(
                    title: context.l10n.aboutWhatItDoes,
                    child: _BulletList(items: [
                      context.l10n.aboutDraw,
                      context.l10n.aboutConvert,
                      context.l10n.aboutAdjust,
                      context.l10n.aboutCompare,
                      context.l10n.aboutSubdivide,
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: context.l10n.aboutOffline,
                    child: Text(
                      context.l10n.aboutOfflineBody,
                      style: AppTypography.sans(
                        size: 13,
                        color: AppColors.textDim,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: context.l10n.aboutBuild,
                    child: Column(
                      children: [
                        _Row(
                          label: context.l10n.aboutVersion,
                          value: _version?.version ?? '…',
                        ),
                        _Divider(),
                        _Row(
                          label: context.l10n.aboutBuildLabel,
                          value: _version?.buildNumber ?? '…',
                        ),
                        _Divider(),
                        _Row(label: context.l10n.aboutPlatform, value: context.l10n.aboutPlatformValue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: context.l10n.aboutCredits,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Row(
                          label: context.l10n.aboutDeveloper,
                          value: context.l10n.aboutDeveloperName,
                        ),
                        _Divider(),
                        _LinkRow(
                          icon: Icons.facebook,
                          label: context.l10n.aboutFacebook,
                          url: 'https://www.facebook.com/zamansheikh.404',
                          accent: accent,
                        ),
                        _Divider(),
                        _LinkRow(
                          icon: Icons.code,
                          label: context.l10n.aboutGithub,
                          url: 'https://github.com/zamansheikh',
                          accent: accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SmallIconButton(
              icon: Icons.chevron_left,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.aboutTitle, style: AppTypography.heroTitle),
                const SizedBox(height: 2),
                Text(
                  context.l10n.aboutTagline,
                  style:
                      AppTypography.mono(size: 11, color: AppColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Color accent;
  final PackageInfo? version;
  const _HeroCard({required this.accent, required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.lineMid),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.limeDim,
              border: Border.all(color: accent),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.terrain, size: 28, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appName,
                  style: AppTypography.sans(size: 20, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  version == null ? '' : 'v${version!.version}',
                  style: AppTypography.mono(
                    size: 12,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.mono(
              size: 10,
              color: AppColors.textFaint,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < items.length - 1 ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.textDim,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: AppTypography.sans(
                      size: 13,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.sans(size: 13, weight: FontWeight.w500),
          ),
          Text(
            value,
            style: AppTypography.mono(size: 12, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.line);
  }
}

/// A credit that opens somewhere.
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color accent;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final failed = context.l10n.aboutOpenLinkFailed;
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          messenger.showSnackBar(SnackBar(content: Text(failed)));
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.sans(size: 13),
              ),
            ),
            Text(
              // The handle, without the scheme and host noise.
              Uri.parse(url).pathSegments.last,
              style: AppTypography.mono(size: 10, color: AppColors.textDim),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 13, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}
