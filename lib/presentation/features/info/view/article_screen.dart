import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../data/articles.dart';

class ArticleScreen extends StatelessWidget {
  final Article article;
  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsBloc>().state.accent;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _TopBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _Hero(article: article, accent: accent),
                  const SizedBox(height: 22),
                  for (var i = 0; i < article.sections.length; i++) ...[
                    _SectionView(
                      section: article.sections[i],
                      accent: accent,
                    ),
                    if (i < article.sections.length - 1)
                      const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SmallIconButton(
            icon: Icons.chevron_left,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.info);
              }
            },
          ),
          Text(
            'Article',
            style: AppTypography.sans(size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Article article;
  final Color accent;
  const _Hero({required this.article, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.limeDim,
            border: Border.all(color: accent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(article.icon, size: 24, color: accent),
        ),
        const SizedBox(height: 14),
        Text(
          article.readTime.toUpperCase(),
          style: AppTypography.mono(
            size: 10,
            color: AppColors.textFaint,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          article.title,
          style: AppTypography.sans(
            size: 24,
            weight: FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          article.summary,
          style: AppTypography.sans(
            size: 14,
            color: AppColors.textDim,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SectionView extends StatelessWidget {
  final ArticleSection section;
  final Color accent;
  const _SectionView({required this.section, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.heading != null) ...[
          Text(
            section.heading!,
            style: AppTypography.sans(
              size: 16,
              weight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          section.body,
          style: AppTypography.sans(
            size: 14,
            color: AppColors.text,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
