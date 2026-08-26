import 'package:flutter/material.dart';

/// One renderable unit of article content.
///
/// [ArticleSection] is the compact heading+prose form the hand-written English
/// articles use. The remaining variants mirror the block types in
/// `docs/land_info.json`, so imported land-record content keeps its tables,
/// images and lists instead of being flattened into paragraphs.
sealed class ArticleBlock {
  const ArticleBlock();
}

class ArticleSection extends ArticleBlock {
  final String? heading;
  final String body;
  const ArticleSection({this.heading, required this.body});
}

class HeadingBlock extends ArticleBlock {
  final String text;
  const HeadingBlock(this.text);
}

class SubHeadingBlock extends ArticleBlock {
  final String text;
  const SubHeadingBlock(this.text);
}

class ParagraphBlock extends ArticleBlock {
  final String text;
  const ParagraphBlock(this.text);
}

/// A bullet whose lead-in phrase is emphasised ahead of the explanation.
class BulletPointBlock extends ArticleBlock {
  final String? title;
  final String text;
  const BulletPointBlock({this.title, required this.text});
}

class BulletListBlock extends ArticleBlock {
  final List<String> items;
  const BulletListBlock(this.items);
}

class NumberedListBlock extends ArticleBlock {
  final List<String> items;
  const NumberedListBlock(this.items);
}

class ImageBlock extends ArticleBlock {
  final String asset;
  final String? caption;
  const ImageBlock({required this.asset, this.caption});
}

class TableBlock extends ArticleBlock {
  final List<String> headers;
  final List<List<String>> rows;
  const TableBlock({required this.headers, required this.rows});
}

class Article {
  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final String readTime; // e.g. "3 min read"
  final List<ArticleBlock> blocks;

  /// Bengali articles need a Bengali-capable face and a slightly looser line
  /// height; the renderer keys off this rather than sniffing the script.
  final bool isBengali;

  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.readTime,
    required this.blocks,
    this.isBengali = false,
  });
}

/// Hand-written English reference articles. The Bengali land-record topics
/// live in `docs/land_info.json` and are merged in at startup — see
/// `land_info_loader.dart`.
const articles = <Article>[
  Article(
    id: 'bd-units',
    title: 'Bangladeshi land units, explained',
    summary:
        'Bigha, katha, chatak, shotok — what each one is and how they relate.',
    icon: Icons.straighten,
    readTime: '3 min read',
    blocks: [
      ArticleSection(
        body:
            'Bangladesh uses a tiered system of traditional land units. Each '
            'one is a fixed multiple of the next, so once you know one, you '
            'can derive the rest.',
      ),
      ArticleSection(
        heading: 'Bigha',
        body:
            '1 bigha = 33 decimal = 20 katha ≈ 1,338.93 m² ≈ 14,400 sq ft.\n\n'
            'It\'s the largest of the four common BD units. Most rural plots '
            'are described in bigha-and-katha.',
      ),
      ArticleSection(
        heading: 'Katha',
        body:
            '1 katha = 1.65 decimal = 16 chatak ≈ 66.89 m² ≈ 720 sq ft.\n\n'
            'Twenty kathas make a bigha. Urban plots are typically sized '
            'in katha.',
      ),
      ArticleSection(
        heading: 'Chatak',
        body:
            '1 chatak ≈ 4.18 m² ≈ 45 sq ft.\n\n'
            'Sixteen chataks make one katha. Useful for very small plots '
            'or fractions.',
      ),
      ArticleSection(
        heading: 'Shotok',
        body:
            '1 shotok = 1 decimal ≈ 40.46 m² ≈ 435.6 sq ft.\n\n'
            'Shotok is the same unit as the South Asian "decimal". 33 '
            'shotok = 1 bigha.',
      ),
      ArticleSection(
        heading: 'Quick conversion table',
        body:
            '• 1 bigha = 20 katha = 320 chatak = 33 shotok\n'
            '• 1 katha = 16 chatak = 1.65 shotok\n'
            '• 1 chatak ≈ 0.103 shotok',
      ),
    ],
  ),
  Article(
    id: 'imperial-vs-metric',
    title: 'Imperial vs metric — which to use',
    summary:
        'When square feet beats square meters and vice versa.',
    icon: Icons.compare_arrows,
    readTime: '2 min read',
    blocks: [
      ArticleSection(
        body:
            'Most of the world uses metric. The US, parts of the UK, and '
            'sectors of Bangladeshi/Indian real estate still default to '
            'imperial. PlotCalc supports both — pick what your buyers, '
            'surveyors, and paperwork already use.',
      ),
      ArticleSection(
        heading: 'Square feet (sq ft)',
        body:
            'Best for residential plots, apartments, urban land deals. Familiar '
            'to most South Asian buyers and quoted in property listings.',
      ),
      ArticleSection(
        heading: 'Square meters (m²)',
        body:
            'The international standard. Use it for technical drawings, '
            'government records, and any document going abroad.',
      ),
      ArticleSection(
        heading: 'Acres / hectares',
        body:
            '1 acre = 43,560 sq ft = 4,046.86 m² = 0.4047 hectare.\n\n'
            'Acres dominate agricultural deals; hectares dominate metric '
            'agriculture and forestry.',
      ),
      ArticleSection(
        heading: 'Conversion math',
        body:
            '• 1 m² = 10.7639 sq ft\n'
            '• 1 sq ft = 0.0929 m²\n'
            '• 1 acre = 4,046.86 m²\n'
            '• 1 hectare = 10,000 m²',
      ),
    ],
  ),
  Article(
    id: 'measuring-irregular',
    title: 'Measuring an irregular plot',
    summary:
        'Three field methods that work when the plot isn\'t a rectangle.',
    icon: Icons.timeline,
    readTime: '4 min read',
    blocks: [
      ArticleSection(
        body:
            'Most real plots aren\'t clean rectangles. Hills, rivers, old '
            'boundaries — they all push the polygon out of shape. Here\'s '
            'how to handle that.',
      ),
      ArticleSection(
        heading: '1. Walk the boundary with GPS',
        body:
            'Walk the entire perimeter, dropping a marker at every corner. '
            'In PlotCalc, use Tap mode and place a vertex at each corner '
            'as you arrive. The shoelace formula handles any number of sides.',
      ),
      ArticleSection(
        heading: '2. Triangulate from a baseline',
        body:
            'Pick two known corners. Measure the distance between them and '
            'the distance from each corner to every other corner. Use the '
            'Type method (Triangle) for each sub-triangle, then sum the areas.',
      ),
      ArticleSection(
        heading: '3. Tape + offsets',
        body:
            'Stretch a tape between two endpoints to form a baseline. Measure '
            'perpendicular offsets to each corner along that baseline. Plot '
            'each corner relative to the baseline — Tap mode again.',
      ),
      ArticleSection(
        heading: 'Tip: always close the loop',
        body:
            'When you finish, the last vertex should connect back to the '
            'first. PlotCalc closes automatically, but verify visually that '
            'the polygon makes sense before saving.',
      ),
    ],
  ),
  Article(
    id: 'shoelace',
    title: 'How polygon area is calculated',
    summary:
        'The shoelace formula in plain language — and why it always works.',
    icon: Icons.calculate_outlined,
    readTime: '3 min read',
    blocks: [
      ArticleSection(
        body:
            'Every closed polygon\'s area can be computed from just its '
            'vertex coordinates. No need for triangulation. The trick is '
            'called the shoelace formula.',
      ),
      ArticleSection(
        heading: 'The formula',
        body:
            'For vertices (x₁,y₁), (x₂,y₂), …, (xₙ,yₙ) listed in order:\n\n'
            'Area = ½ |Σ (xᵢ · yᵢ₊₁ − xᵢ₊₁ · yᵢ)|\n\n'
            'You "lace" through the coordinates like a shoe — each pair of '
            'adjacent points contributes to a running sum.',
      ),
      ArticleSection(
        heading: 'Why it works',
        body:
            'Each term is the signed area of a triangle from the origin to '
            'an edge. Going clockwise around the polygon, the inside '
            'triangles cancel the outside triangles, leaving just the '
            'enclosed area. The absolute value handles direction.',
      ),
      ArticleSection(
        heading: 'Practical notes',
        body:
            '• Works for any simple polygon — triangle, hexagon, freeform.\n'
            '• Doesn\'t require the polygon to be convex.\n'
            '• Self-intersecting polygons give the wrong answer; PlotCalc '
            'doesn\'t check for self-intersection, so visually verify the '
            'shape before trusting the area.',
      ),
    ],
  ),
  Article(
    id: 'diagonals',
    title: 'Why diagonals matter for surveying',
    summary:
        'Use them to verify squareness and catch field-measurement errors.',
    icon: Icons.timeline,
    readTime: '2 min read',
    blocks: [
      ArticleSection(
        body:
            'Side lengths alone don\'t pin down a quadrilateral. A '
            'parallelogram and a rectangle can have identical sides but '
            'different shapes. Diagonals fix that.',
      ),
      ArticleSection(
        heading: 'The 3-4-5 trick',
        body:
            'For a true rectangle, both diagonals are equal. If your plot '
            'is supposed to be rectangular and the diagonals differ by '
            'more than 1%, your corners aren\'t at right angles. Re-measure.',
      ),
      ArticleSection(
        heading: 'Reading diagonals in PlotCalc',
        body:
            'On the Draw screen, tap "DIAG" in the top-right of the canvas '
            'to overlay all diagonals with their lengths. Tap any diagonal '
            'label to edit its length — one of its endpoints will slide '
            'along the diagonal axis to make it match.',
      ),
      ArticleSection(
        heading: 'When diagonals lie',
        body:
            'Diagonals only verify shape, not absolute size. A scaled-down '
            'rectangle has the same diagonal/side ratio. Always combine '
            'with at least one absolute side measurement.',
      ),
    ],
  ),
];
