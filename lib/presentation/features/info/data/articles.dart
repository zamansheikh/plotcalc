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

/// Hand-written reference articles, in English. The Bengali versions are in
/// [articlesBn]; the Bengali land-record topics live in
/// `docs/land_info.json` and are merged in at startup — see
/// `land_info_loader.dart`.
const articlesEn = <Article>[
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
            '1 bigha = 20 katha = 320 chatak = 14,400 sq ft ≈ 1,337.80 m².\n\n'
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
            '1 shotok = 1 decimal = 435.6 sq ft ≈ 40.47 m².\n\n'
            'Shotok is the same unit as the South Asian "decimal" — exactly '
            'one hundredth of an acre. A bigha is 33.06 shotok, which is why '
            'it is often quoted loosely as "33 decimal".',
      ),
      ArticleSection(
        heading: 'Regional sizes: the Mymensingh bigha',
        body:
            'Bigha and katha are not the same size everywhere. The figures '
            'above are the standard used in Dhaka and in most land deeds; '
            'Rajshahi, Dinajpur and Bogura, for instance, work to a katha of '
            'about 805 sq ft.\n\n'
            'PlotCalc ships the Mymensingh pair as separate units so you '
            'never have to mix conventions:\n\n'
            '• 1 katha (Mymensingh) = 6.5 shotok = 2,831.4 sq ft\n'
            '• 1 bigha (Mymensingh) = 20 katha (M) = 130 shotok = 1.3 acre\n\n'
            'That makes a Mymensingh bigha a little over four times the '
            'standard one — always confirm which convention a deed uses '
            'before converting.',
      ),
      ArticleSection(
        heading: 'Quick conversion table',
        body:
            '• 1 bigha = 20 katha = 320 chatak ≈ 33.06 shotok\n'
            '• 1 katha = 16 chatak = 1.65 shotok = 720 sq ft\n'
            '• 1 chatak = 45 sq ft ≈ 0.103 shotok\n'
            '• 1 acre = 100 shotok ≈ 3.025 bigha',
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

/// The same five articles in Bengali.
///
/// Kept as a parallel list rather than a translation of each string: these
/// are prose, and a land article reads differently in Bengali than a
/// sentence-by-sentence rendering of the English would. Figures are given in
/// Bengali numerals to match the land-record articles alongside them.
const articlesBn = <Article>[
  Article(
    id: 'bd-units',
    isBengali: true,
    title: 'বাংলাদেশের জমির একক',
    summary: 'বিঘা, কাঠা, ছটাক, শতক — কোনটি কী এবং একটির সঙ্গে আরেকটির সম্পর্ক।',
    icon: Icons.straighten,
    readTime: '৩ মিনিট পড়া',
    blocks: [
      ArticleSection(
        body:
            'বাংলাদেশে জমির এককগুলো ধাপে ধাপে সাজানো। প্রতিটি একক পরেরটির একটি '
            'নির্দিষ্ট গুণিতক, তাই একটি জানা থাকলে বাকিগুলো বের করা যায়।',
      ),
      ArticleSection(
        heading: 'বিঘা',
        body:
            '১ বিঘা = ২০ কাঠা = ৩২০ ছটাক = ১৪,৪০০ বর্গফুট ≈ ১,৩৩৭.৮০ বর্গমিটার।\n\n'
            'প্রচলিত চারটি এককের মধ্যে এটিই সবচেয়ে বড়। গ্রামাঞ্চলের বেশিরভাগ '
            'জমি বিঘা ও কাঠায় বলা হয়।',
      ),
      ArticleSection(
        heading: 'কাঠা',
        body:
            '১ কাঠা = ১.৬৫ শতক = ১৬ ছটাক ≈ ৬৬.৮৯ বর্গমিটার ≈ ৭২০ বর্গফুট।\n\n'
            'বিশ কাঠায় এক বিঘা। শহরের জমি সাধারণত কাঠায় মাপা হয়।',
      ),
      ArticleSection(
        heading: 'ছটাক',
        body:
            '১ ছটাক ≈ ৪.১৮ বর্গমিটার ≈ ৪৫ বর্গফুট।\n\n'
            'ষোলো ছটাকে এক কাঠা। খুব ছোট জমি বা ভগ্নাংশ বোঝাতে কাজে লাগে।',
      ),
      ArticleSection(
        heading: 'শতক',
        body:
            '১ শতক = ১ ডেসিমেল = ৪৩৫.৬ বর্গফুট ≈ ৪০.৪৭ বর্গমিটার।\n\n'
            'শতক আর দক্ষিণ এশিয়ার "ডেসিমেল" একই একক — ঠিক এক একরের একশ ভাগের '
            'এক ভাগ। এক বিঘা ৩৩.০৬ শতক, সেজন্যই একে অনেক সময় আন্দাজে '
            '"৩৩ ডেসিমেল" বলা হয়।',
      ),
      ArticleSection(
        heading: 'আঞ্চলিক পার্থক্য: ময়মনসিংহের বিঘা',
        body:
            'বিঘা আর কাঠা সব জায়গায় সমান নয়। উপরের হিসাব ঢাকা ও বেশিরভাগ '
            'দলিলে ব্যবহৃত আদর্শ মাপ; রাজশাহী, দিনাজপুর ও বগুড়ায় এক কাঠা '
            'প্রায় ৮০৫ বর্গফুট ধরা হয়।\n\n'
            'ময়মনসিংহের বিঘা ও কাঠা এই অ্যাপে আলাদা একক হিসেবেই আছে, যাতে দুই '
            'রীতি মিশে না যায়:\n\n'
            '• ১ কাঠা (ময়মনসিংহ) = ৬.৫ শতক = ২,৮৩১.৪ বর্গফুট\n'
            '• ১ বিঘা (ময়মনসিংহ) = ২০ কাঠা (ময়) = ১৩০ শতক = ১.৩ একর\n\n'
            'অর্থাৎ ময়মনসিংহের এক বিঘা আদর্শ বিঘার চার গুণেরও কিছু বেশি — '
            'রূপান্তরের আগে দলিলে কোন রীতি ব্যবহার হয়েছে তা মিলিয়ে নিন।',
      ),
      ArticleSection(
        heading: 'দ্রুত হিসাব',
        body:
            '• ১ বিঘা = ২০ কাঠা = ৩২০ ছটাক ≈ ৩৩.০৬ শতক\n'
            '• ১ কাঠা = ১৬ ছটাক = ১.৬৫ শতক = ৭২০ বর্গফুট\n'
            '• ১ ছটাক = ৪৫ বর্গফুট ≈ ০.১০৩ শতক\n'
            '• ১ একর = ১০০ শতক ≈ ৩.০২৫ বিঘা',
      ),
    ],
  ),
  Article(
    id: 'imperial-vs-metric',
    isBengali: true,
    title: 'বর্গফুট না বর্গমিটার — কোনটি ব্যবহার করবেন',
    summary: 'কখন বর্গফুট সুবিধাজনক আর কখন বর্গমিটার।',
    icon: Icons.compare_arrows,
    readTime: '২ মিনিট পড়া',
    blocks: [
      ArticleSection(
        body:
            'পৃথিবীর বেশিরভাগ দেশ মেট্রিক পদ্ধতি ব্যবহার করে। যুক্তরাষ্ট্র, '
            'যুক্তরাজ্যের কিছু অংশ এবং বাংলাদেশ ও ভারতের জমি-বাণিজ্যের বড় অংশ '
            'এখনো বর্গফুটেই চলে। এই অ্যাপে দুটোই আছে — আপনার ক্রেতা, আমিন ও '
            'কাগজপত্র যেটিতে অভ্যস্ত সেটিই বেছে নিন।',
      ),
      ArticleSection(
        heading: 'বর্গফুট',
        body:
            'বাসাবাড়ির জমি, ফ্ল্যাট ও শহুরে জমির লেনদেনে সবচেয়ে প্রচলিত। '
            'দক্ষিণ এশিয়ার ক্রেতাদের কাছে পরিচিত এবং বিজ্ঞাপনে এতেই লেখা হয়।',
      ),
      ArticleSection(
        heading: 'বর্গমিটার',
        body:
            'আন্তর্জাতিক মান। কারিগরি নকশা, সরকারি রেকর্ড এবং দেশের বাইরে '
            'যাওয়া যেকোনো কাগজে এটিই ব্যবহার করুন।',
      ),
      ArticleSection(
        heading: 'একর ও হেক্টর',
        body:
            '১ একর = ৪৩,৫৬০ বর্গফুট = ৪,০৪৬.৮৬ বর্গমিটার = ০.৪০৪৭ হেক্টর।\n\n'
            'কৃষিজমির লেনদেনে একর বেশি চলে; মেট্রিক কৃষি ও বনায়নে হেক্টর।',
      ),
      ArticleSection(
        heading: 'রূপান্তরের হিসাব',
        body:
            '• ১ বর্গমিটার = ১০.৭৬৩৯ বর্গফুট\n'
            '• ১ বর্গফুট = ০.০৯২৯ বর্গমিটার\n'
            '• ১ একর = ৪,০৪৬.৮৬ বর্গমিটার\n'
            '• ১ হেক্টর = ১০,০০০ বর্গমিটার',
      ),
    ],
  ),
  Article(
    id: 'measuring-irregular',
    isBengali: true,
    title: 'অনিয়মিত আকৃতির জমি মাপা',
    summary: 'জমি চারকোনা না হলে মাঠে যে তিনটি পদ্ধতি কাজে লাগে।',
    icon: Icons.timeline,
    readTime: '৪ মিনিট পড়া',
    blocks: [
      ArticleSection(
        body:
            'বাস্তবে বেশিরভাগ জমিই পরিপাটি আয়তক্ষেত্র নয়। টিলা, নদী, পুরোনো '
            'সীমানা — সবই আকৃতি বদলে দেয়। এমন জমি যেভাবে মাপবেন।',
      ),
      ArticleSection(
        heading: '১. জিপিএস নিয়ে সীমানা ধরে হাঁটুন',
        body:
            'পুরো সীমানা ধরে হেঁটে প্রতিটি কোণে একটি করে বিন্দু ফেলুন। এই '
            'অ্যাপে ট্যাপ পদ্ধতি বেছে নিয়ে প্রতিটি কোণে পৌঁছে সেখানে একটি কোণ '
            'বসান। সূত্রটি যত খুশি বাহু সামলাতে পারে।',
      ),
      ArticleSection(
        heading: '২. একটি ভিত্তিরেখা থেকে ত্রিভুজ করুন',
        body:
            'পরিচিত দুটি কোণ বেছে নিন। তাদের মধ্যকার দূরত্ব এবং প্রতিটি কোণ '
            'থেকে বাকি কোণগুলোর দূরত্ব মাপুন। প্রতিটি ছোট ত্রিভুজের জন্য '
            '"লিখুন" পদ্ধতিতে ত্রিভুজ বেছে নিয়ে ক্ষেত্রফলগুলো যোগ করুন।',
      ),
      ArticleSection(
        heading: '৩. ফিতা ও লম্ব দূরত্ব',
        body:
            'দুই প্রান্তের মাঝে ফিতা টেনে একটি ভিত্তিরেখা তৈরি করুন। সেই রেখা '
            'থেকে প্রতিটি কোণের লম্ব দূরত্ব মাপুন। এরপর ভিত্তিরেখার সাপেক্ষে '
            'প্রতিটি কোণ বসান — আবারও ট্যাপ পদ্ধতিতে।',
      ),
      ArticleSection(
        heading: 'পরামর্শ: সীমানা বন্ধ করুন',
        body:
            'শেষ কোণটি যেন প্রথম কোণের সঙ্গে মিলে যায়। অ্যাপ নিজে থেকেই সীমানা '
            'বন্ধ করে দেয়, তবু সংরক্ষণের আগে আকৃতিটি দেখে নিশ্চিত হয়ে নিন।',
      ),
    ],
  ),
  Article(
    id: 'shoelace',
    isBengali: true,
    title: 'বহুভুজের ক্ষেত্রফল কীভাবে বের হয়',
    summary: 'শুলেস সূত্র সহজ ভাষায় — এবং কেন এটি সবসময় কাজ করে।',
    icon: Icons.calculate_outlined,
    readTime: '৩ মিনিট পড়া',
    blocks: [
      ArticleSection(
        body:
            'যেকোনো বদ্ধ বহুভুজের ক্ষেত্রফল শুধু তার কোণগুলোর স্থানাঙ্ক থেকেই '
            'বের করা যায়। ত্রিভুজে ভাগ করার দরকার নেই। কৌশলটির নাম শুলেস সূত্র।',
      ),
      ArticleSection(
        heading: 'সূত্রটি',
        body:
            'ক্রম অনুসারে সাজানো কোণ (x₁,y₁), (x₂,y₂), …, (xₙ,yₙ)-এর জন্য:\n\n'
            'ক্ষেত্রফল = ½ |Σ (xᵢ · yᵢ₊₁ − xᵢ₊₁ · yᵢ)|\n\n'
            'জুতোর ফিতা বাঁধার মতো স্থানাঙ্কগুলো আড়াআড়ি গুণ করা হয় — '
            'পাশাপাশি প্রতিটি জোড়া যোগফলে অবদান রাখে।',
      ),
      ArticleSection(
        heading: 'কেন কাজ করে',
        body:
            'প্রতিটি পদ আসলে মূলবিন্দু থেকে একটি বাহু পর্যন্ত ত্রিভুজের '
            'চিহ্নযুক্ত ক্ষেত্রফল। বহুভুজ ধরে ঘুরলে ভেতরের ত্রিভুজগুলো বাইরের '
            'ত্রিভুজগুলোকে কেটে দেয়, থাকে কেবল ঘেরা জায়গাটুকু। পরম মান দিক '
            'সামলে নেয়।',
      ),
      ArticleSection(
        heading: 'কাজের কথা',
        body:
            '• যেকোনো সরল বহুভুজে চলে — ত্রিভুজ, ষড়ভুজ, মুক্ত আকৃতি।\n'
            '• বহুভুজ উত্তল হওয়া লাগে না।\n'
            '• সীমানা নিজের সঙ্গে কাটাকাটি করলে ফল ভুল আসে; অ্যাপ সেটি যাচাই '
            'করে না, তাই ক্ষেত্রফলে ভরসা করার আগে আকৃতিটি চোখে দেখে নিন।',
      ),
    ],
  ),
  Article(
    id: 'diagonals',
    isBengali: true,
    title: 'জরিপে কর্ণ কেন গুরুত্বপূর্ণ',
    summary: 'সমকোণ যাচাই ও মাঠের মাপের ভুল ধরতে কর্ণ কাজে লাগে।',
    icon: Icons.timeline,
    readTime: '২ মিনিট পড়া',
    blocks: [
      ArticleSection(
        body:
            'শুধু বাহুর দৈর্ঘ্য দিয়ে চতুর্ভুজের আকৃতি ঠিক হয় না। সামান্তরিক ও '
            'আয়তক্ষেত্রের বাহু হুবহু এক হতে পারে, অথচ আকৃতি আলাদা। কর্ণ সেই '
            'সমস্যা মিটিয়ে দেয়।',
      ),
      ArticleSection(
        heading: 'সহজ যাচাই',
        body:
            'সত্যিকারের আয়তক্ষেত্রে দুটি কর্ণ সমান হয়। জমিটি আয়তাকার হওয়ার '
            'কথা থাকলেও যদি কর্ণ দুটির পার্থক্য ১%-এর বেশি হয়, তবে কোণগুলো '
            'সমকোণ নয়। আবার মাপুন।',
      ),
      ArticleSection(
        heading: 'অ্যাপে কর্ণ দেখা',
        body:
            'আঁকার পর্দায় ক্যানভাসের উপরে ডানদিকের "কর্ণ" বোতামে চাপ দিলে সব '
            'কর্ণ ও তাদের দৈর্ঘ্য দেখা যায়। যেকোনো কর্ণের লেখায় চাপ দিয়ে তার '
            'দৈর্ঘ্য বদলানো যায় — কর্ণ বরাবর তার এক প্রান্ত সরে গিয়ে মাপটি '
            'মিলিয়ে দেবে।',
      ),
      ArticleSection(
        heading: 'কর্ণ যেখানে বিভ্রান্ত করে',
        body:
            'কর্ণ কেবল আকৃতি যাচাই করে, প্রকৃত আকার নয়। ছোট করে আঁকা '
            'আয়তক্ষেত্রেও কর্ণ ও বাহুর অনুপাত একই থাকে। তাই অন্তত একটি বাহুর '
            'প্রকৃত মাপ সঙ্গে রাখুন।',
      ),
    ],
  ),
];
