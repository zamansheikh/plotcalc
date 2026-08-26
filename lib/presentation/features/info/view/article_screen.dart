import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/settings/settings_bloc.dart';
import '../../../shared/widgets/phone_chrome.dart';
import '../data/articles.dart';
import '../../../../l10n/l10n.dart';

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
                  for (var i = 0; i < article.blocks.length; i++) ...[
                    _BlockView(
                      block: article.blocks[i],
                      article: article,
                      accent: accent,
                    ),
                    if (i < article.blocks.length - 1)
                      const SizedBox(height: 16),
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
            context.l10n.infoArticle,
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
          style: article.isBengali
              ? AppTypography.bangla(
                  size: 22,
                  weight: FontWeight.w600,
                  height: 1.45,
                )
              : AppTypography.sans(
                  size: 24,
                  weight: FontWeight.w600,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          article.summary,
          style: article.isBengali
              ? AppTypography.bangla(
                  size: 13,
                  color: AppColors.textDim,
                  height: 1.6,
                )
              : AppTypography.sans(
                  size: 14,
                  color: AppColors.textDim,
                  height: 1.5,
                ),
        ),
      ],
    );
  }
}

/// Renders one [ArticleBlock]. The English articles are all
/// [ArticleSection]s; the imported Bengali topics use the richer variants.
class _BlockView extends StatelessWidget {
  final ArticleBlock block;
  final Article article;
  final Color accent;
  const _BlockView({
    required this.block,
    required this.article,
    required this.accent,
  });

  TextStyle _body({Color color = AppColors.text, double size = 14}) =>
      article.isBengali
      ? AppTypography.bangla(size: size, color: color, height: 1.75)
      : AppTypography.sans(size: size, color: color, height: 1.6);

  TextStyle _title(double size, Color color) => article.isBengali
      ? AppTypography.bangla(
          size: size,
          weight: FontWeight.w600,
          color: color,
          height: 1.5,
        )
      : AppTypography.sans(size: size, weight: FontWeight.w600, color: color);

  @override
  Widget build(BuildContext context) {
    switch (block) {
      case ArticleSection(:final heading, :final body):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) ...[
              Text(heading, style: _title(16, accent)),
              const SizedBox(height: 8),
            ],
            Text(body, style: _body()),
          ],
        );

      case HeadingBlock(:final text):
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Text(text, style: _title(18, accent)),
        );

      case SubHeadingBlock(:final text):
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(text, style: _title(15, AppColors.text)),
        );

      case ParagraphBlock(:final text):
        return Text(text, style: _body());

      case BulletPointBlock(:final title, :final text):
        return _Bullet(
          marker: '•',
          accent: accent,
          child: Text.rich(
            TextSpan(
              children: [
                if (title != null && title.isNotEmpty)
                  TextSpan(
                    text: '$title — ',
                    style: _body().copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                TextSpan(text: text, style: _body(color: AppColors.textDim)),
              ],
            ),
          ),
        );

      case BulletListBlock(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Bullet(
                  marker: '•',
                  accent: accent,
                  child: Text(item, style: _body(color: AppColors.textDim)),
                ),
              ),
          ],
        );

      case NumberedListBlock(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _Bullet(
                  marker: '${i + 1}.',
                  accent: accent,
                  child: Text(items[i], style: _body(color: AppColors.textDim)),
                ),
              ),
          ],
        );

      case ImageBlock(:final asset, :final caption):
        return _ArticleImage(asset: asset, caption: caption, article: article);

      case TableBlock(:final headers, :final rows):
        return _ArticleTable(
          headers: headers,
          rows: rows,
          accent: accent,
          article: article,
        );
    }
  }
}

class _Bullet extends StatelessWidget {
  final String marker;
  final Color accent;
  final Widget child;
  const _Bullet({
    required this.marker,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            marker,
            style: AppTypography.mono(size: 12, color: accent, height: 1.7),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Khatiyan and mouza-map scans are dense documents — unreadable at column
/// width — so tapping one opens a pan/zoom viewer.
class _ArticleImage extends StatelessWidget {
  final String asset;
  final String? caption;
  final Article article;
  const _ArticleImage({
    required this.asset,
    required this.caption,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.92),
              builder: (_) => _ImageViewer(asset: asset, caption: caption),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: article.isBengali
                ? AppTypography.bangla(
                    size: 11,
                    color: AppColors.textFaint,
                    height: 1.5,
                  )
                : AppTypography.mono(size: 10, color: AppColors.textFaint),
          ),
        ],
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String asset;
  final String? caption;
  const _ImageViewer({required this.asset, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: Image.asset(asset, fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: SmallIconButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Symbol/conversion tables can be wider than the screen, so the table
/// scrolls horizontally inside the article rather than overflowing it.
class _ArticleTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final Color accent;
  final Article article;
  const _ArticleTable({
    required this.headers,
    required this.rows,
    required this.accent,
    required this.article,
  });

  TextStyle _cell({required bool header}) => article.isBengali
      ? AppTypography.bangla(
          size: 12,
          weight: header ? FontWeight.w600 : FontWeight.w400,
          color: header ? accent : AppColors.textDim,
          height: 1.5,
        )
      : AppTypography.sans(
          size: 12,
          weight: header ? FontWeight.w600 : FontWeight.w400,
          color: header ? accent : AppColors.textDim,
          height: 1.5,
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 40,
          ),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: AppColors.line),
              verticalInside: BorderSide(color: AppColors.line),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.surfaceHi),
                children: [
                  for (final h in headers) _cellBox(h, header: true),
                ],
              ),
              for (final row in rows)
                TableRow(
                  children: [
                    // Guard against ragged rows in the source JSON.
                    for (var i = 0; i < headers.length; i++)
                      _cellBox(i < row.length ? row[i] : '', header: false),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cellBox(String text, {required bool header}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: Text(text, style: _cell(header: header)),
  );
}
