import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'articles.dart';

/// Bengali land-record reference content (khatiyan, mouza maps, buying and
/// dispute guides). It ships as JSON rather than Dart so the app and the
/// GitHub Pages site under `docs/` stay on one copy of the text.
///
/// Parsed once during startup by [load] so the Info tab can read [all]
/// synchronously and never has to show a spinner.
class InfoContent {
  InfoContent._();

  static const _asset = 'docs/land_info.json';

  static List<Article> _imported = const [];

  /// Every article the Info tab shows: the hand-written English ones first,
  /// then the imported Bengali land-record topics.
  static List<Article> get all => [...articles, ..._imported];

  /// Same catalogue, but articles written in the reader's language come
  /// first. Article bodies are content, not UI strings, so they aren't
  /// translated — ordering is what makes the list useful in either language.
  static List<Article> forLocale(Locale locale) {
    final wantsBengali = locale.languageCode == 'bn';
    final matching = all.where((a) => a.isBengali == wantsBengali);
    final rest = all.where((a) => a.isBengali != wantsBengali);
    return [...matching, ...rest];
  }

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString(_asset);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final topics = decoded['topics'] as List? ?? const [];
      _imported = topics
          .whereType<Map<String, dynamic>>()
          .map(_articleFromTopic)
          .toList(growable: false);
    } catch (_) {
      // Malformed or missing content must never block app start — the Info
      // tab just falls back to the built-in English articles.
      _imported = const [];
    }
  }

  static Article _articleFromTopic(Map<String, dynamic> topic) {
    final blocks = (topic['content'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_blockFrom)
        .whereType<ArticleBlock>()
        .toList(growable: false);

    final id = topic['id'] as String? ?? '';
    return Article(
      id: id,
      title: topic['title'] as String? ?? '',
      summary: topic['description'] as String? ?? _firstProse(blocks),
      icon: _iconFor(id),
      readTime: _readTime(blocks),
      blocks: blocks,
      isBengali: true,
    );
  }

  static ArticleBlock? _blockFrom(Map<String, dynamic> b) {
    String text() => b['text'] as String? ?? '';
    List<String> items() =>
        (b['items'] as List? ?? const []).map((e) => '$e').toList();

    switch (b['type']) {
      case 'header':
        return HeadingBlock(text());
      case 'sub_header':
        return SubHeadingBlock(text());
      case 'paragraph':
        return ParagraphBlock(text());
      case 'bullet_point':
        return BulletPointBlock(title: b['title'] as String?, text: text());
      case 'bullet_list':
        return BulletListBlock(items());
      case 'numbered_list':
        return NumberedListBlock(items());
      case 'image':
        // Only bundled assets are supported; the JSON has no network images.
        if (b['source'] != 'asset') return null;
        final url = b['url'] as String?;
        if (url == null) return null;
        return ImageBlock(asset: url, caption: b['caption'] as String?);
      case 'table':
        return TableBlock(
          headers: (b['headers'] as List? ?? const []).map((e) => '$e').toList(),
          rows: (b['rows'] as List? ?? const [])
              .map((r) => (r as List).map((c) => '$c').toList())
              .toList(),
        );
      default:
        return null;
    }
  }

  /// Fallback summary when a topic omits `description`.
  static String _firstProse(List<ArticleBlock> blocks) {
    for (final b in blocks) {
      if (b is ParagraphBlock) {
        return b.text.length > 120 ? '${b.text.substring(0, 117)}…' : b.text;
      }
    }
    return '';
  }

  /// The JSON carries no reading estimate, so derive one at roughly 180
  /// words per minute — a comfortable pace for Bengali prose.
  static String _readTime(List<ArticleBlock> blocks) {
    var words = 0;
    void count(String s) =>
        words += s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    for (final b in blocks) {
      switch (b) {
        case HeadingBlock(:final text):
        case SubHeadingBlock(:final text):
        case ParagraphBlock(:final text):
          count(text);
        case BulletPointBlock(:final title, :final text):
          if (title != null) count(title);
          count(text);
        case BulletListBlock(:final items):
        case NumberedListBlock(:final items):
          items.forEach(count);
        case TableBlock(:final rows):
          for (final r in rows) {
            r.forEach(count);
          }
        case ImageBlock():
        case ArticleSection():
          break;
      }
    }
    final minutes = (words / 180).ceil().clamp(1, 99);
    return '${_bengaliDigits('$minutes')} মিনিট পড়া';
  }

  static const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  static String _bengaliDigits(String s) => s
      .split('')
      .map((c) {
        final d = int.tryParse(c);
        return d == null ? c : _bnDigits[d];
      })
      .join();

  static IconData _iconFor(String id) => switch (id) {
    'khatiyan' => Icons.description_outlined,
    'khatiyan_identification' => Icons.manage_search,
    'land_buying_guide_detailed' => Icons.handshake_outlined,
    'land_legal_disputes_bd' => Icons.gavel,
    'land_measurement_symbols' => Icons.tag,
    'mouza_map_symbols' => Icons.map_outlined,
    _ => Icons.article_outlined,
  };
}
