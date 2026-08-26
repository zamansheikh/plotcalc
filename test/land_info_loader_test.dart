import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcalc/presentation/features/info/data/articles.dart';
import 'package:plotcalc/presentation/features/info/data/land_info_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => InfoContent.load());

  test('imports every Bengali topic from docs/land_info.json', () async {
    await InfoContent.load();
    final imported = InfoContent.all.where((a) => a.isBengali).toList();
    expect(imported.length, 6);
    expect(
      imported.map((a) => a.id),
      containsAll(<String>[
        'khatiyan',
        'khatiyan_identification',
        'land_buying_guide_detailed',
        'land_legal_disputes_bd',
        'land_measurement_symbols',
        'mouza_map_symbols',
      ]),
    );
  });

  test('keeps the reader\'s own articles ahead of the imported ones', () async {
    await InfoContent.load();
    expect(InfoContent.all.length, articlesEn.length + articlesBn.length + 6);
    expect(
      InfoContent.forLocale(const Locale('en')).take(articlesEn.length)
          .every((a) => !a.isBengali),
      isTrue,
    );
  });

  test('every block type survives the mapping', () async {
    await InfoContent.load();
    final blocks = InfoContent.all
        .where((a) => a.isBengali)
        .expand((a) => a.blocks)
        .toList();

    expect(blocks.whereType<HeadingBlock>().length, 23);
    expect(blocks.whereType<SubHeadingBlock>().length, 4);
    expect(blocks.whereType<ParagraphBlock>().length, 40);
    expect(blocks.whereType<BulletPointBlock>().length, 27);
    expect(blocks.whereType<BulletListBlock>().length, 7);
    expect(blocks.whereType<NumberedListBlock>().length, 1);
    expect(blocks.whereType<ImageBlock>().length, 11);
    expect(blocks.whereType<TableBlock>().length, 5);
  });

  test('titles, summaries and read times are populated', () async {
    await InfoContent.load();
    for (final a in InfoContent.all.where((a) => a.isBengali)) {
      expect(a.title, isNotEmpty, reason: a.id);
      expect(a.summary, isNotEmpty, reason: a.id);
      expect(a.readTime, contains('মিনিট'), reason: a.id);
      expect(a.blocks, isNotEmpty, reason: a.id);
    }
  });

  test('tables are rectangular enough to render', () async {
    await InfoContent.load();
    final tables = InfoContent.all
        .where((a) => a.isBengali)
        .expand((a) => a.blocks)
        .whereType<TableBlock>();
    for (final t in tables) {
      expect(t.headers, isNotEmpty);
      expect(t.rows, isNotEmpty);
    }
  });
}
