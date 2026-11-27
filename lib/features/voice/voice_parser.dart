import '../../core/money/money.dart';
import '../../data/db/app_database.dart';

/// What was understood from a spoken entry. Anything null is left for the
/// user to fill in; nothing is saved without them confirming.
typedef VoiceEntry = ({
  TransactionType? type,
  Money? amount,
  String? categoryId,
  String? note,
});

/// Turns "rickshaw 50 taka", "চা বিশ টাকা", "salary 45 thousand" or
/// "lunch 1.5k" into an entry.
///
/// [categories] are matched by their own names first (so the user's custom
/// categories work), then built-ins by keyword. [names] gives each
/// category's display name (built-ins are translated).
VoiceEntry parseVoiceEntry(
  String spoken, {
  required List<Category> categories,
  required String Function(Category) names,
}) {
  final text = _normalize(spoken);
  if (text.isEmpty) {
    return (type: null, amount: null, categoryId: null, note: null);
  }
  final words = text.split(' ');

  final (amount, used) = _findAmount(words);
  final isIncome =
      words.any(_lex.income.contains) ||
      text.contains('got paid') ||
      text.contains(_unify('টাকা পেলাম'));
  final kind = isIncome ? CategoryKind.income : CategoryKind.expense;
  final category = _matchCategory(text, words, categories, names, kind);

  // The note is what was said, minus the amount and filler words.
  final noteWords = <String>[
    for (var i = 0; i < words.length; i++)
      if (!used.contains(i) && !_lex.filler.contains(words[i])) words[i],
  ];
  var note = noteWords.join(' ').trim();
  if (note.isNotEmpty) note = note[0].toUpperCase() + note.substring(1);

  return (
    type: isIncome ? TransactionType.income : null,
    amount: amount,
    categoryId: category?.id,
    note: note.isEmpty ? null : note,
  );
}

// ------------------------------------------------------------ text --

/// Bangla য়/ড়/ঢ় can be typed as one code point or as letter + nukta.
/// Everything (speech and word lists) is unified to letter + nukta.
String _unify(String s) =>
    s.replaceAll('য়', 'য়').replaceAll('ড়', 'ড়').replaceAll('ঢ়', 'ঢ়');

const _bnDigits = '০১২৩৪৫৬৭৮৯';

String _normalize(String s) {
  final buf = StringBuffer();
  for (final rune in _unify(s.toLowerCase()).runes) {
    final ch = String.fromCharCode(rune);
    final d = _bnDigits.indexOf(ch);
    buf.write(d >= 0 ? '$d' : ch);
  }
  return buf
      .toString()
      // "৳50", "50tk", "1,250" → separate tokens, no grouping commas.
      .replaceAll('৳', ' taka ')
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}${m[2]}')
      .replaceAllMapped(RegExp(r'(\d)(tk|taka|টাকা)'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}. ]', unicode: true), ' ')
      .replaceAll(RegExp(r'(?<!\d)\.|\.(?!\d)'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

// ----------------------------------------------------------- lexicon --

class _Lexicon {
  _Lexicon()
    : units = {for (final e in _unitWords.entries) _unify(e.key): e.value},
      multipliers = {
        for (final e in _multiplierWords.entries) _unify(e.key): e.value,
      },
      currency = _currencyWords.map(_unify).toSet(),
      income = _incomeWords.map(_unify).toSet(),
      filler = _fillerWords.map(_unify).toSet(),
      keywords = {
        for (final e in _keywordWords.entries)
          e.key: e.value.map(_unify).toSet(),
      };

  final Map<String, num> units;
  final Map<String, int> multipliers;
  final Set<String> currency;
  final Set<String> income;
  final Set<String> filler;
  final Map<String, Set<String>> keywords;
}

final _lex = _Lexicon();

const _unitWords = <String, num>{
  'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, //
  'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
  'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
  'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
  'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
  'seventy': 70, 'eighty': 80, 'ninety': 90,
  // Bangla: common spoken amounts (recognizers usually give digits).
  'এক': 1, 'দুই': 2, 'দু': 2, 'তিন': 3, 'চার': 4, 'পাঁচ': 5, 'ছয়': 6,
  'সাত': 7, 'আট': 8, 'নয়': 9, 'দশ': 10, 'এগারো': 11, 'বারো': 12,
  'তেরো': 13, 'চৌদ্দ': 14, 'পনেরো': 15, 'ষোল': 16, 'সতেরো': 17,
  'আঠারো': 18, 'উনিশ': 19, 'বিশ': 20, 'কুড়ি': 20, 'পঁচিশ': 25,
  'ত্রিশ': 30, 'তিরিশ': 30, 'পঁয়ত্রিশ': 35, 'চল্লিশ': 40,
  'পঁয়তাল্লিশ': 45, 'পঞ্চাশ': 50, 'ষাট': 60, 'সত্তর': 70,
  'পঁচাত্তর': 75, 'আশি': 80, 'নব্বই': 90, 'দেড়': 1.5, 'আড়াই': 2.5,
};

const _multiplierWords = <String, int>{
  'hundred': 100, 'thousand': 1000, 'k': 1000, 'lakh': 100000, //
  'lac': 100000, 'lakhs': 100000, 'শ': 100, 'শো': 100, 'শত': 100,
  'হাজার': 1000, 'লাখ': 100000, 'লক্ষ': 100000,
};

const _currencyWords = ['taka', 'tk', 'টাকা', 'bdt', 'rupees', 'rs'];

const _incomeWords = [
  'salary', 'income', 'received', 'receive', 'got', 'earned', 'bonus', //
  'refund', 'বেতন', 'আয়', 'পেলাম', 'পেয়েছি', 'বোনাস',
];

const _fillerWords = [
  'for',
  'on',
  'spent',
  'paid',
  'pay',
  'a',
  'the',
  'of',
  'to',
  'and',
  'i',
  'বাবদ',
  'দিলাম',
  'দিয়েছি',
  'খরচ',
  'করলাম',
  'জন্য',
  'টা',
];

/// Built-in categories (by systemKey) and the words that point to them.
const _keywordWords = <String, List<String>>{
  'food': [
    'lunch', 'dinner', 'breakfast', 'tea', 'cha', 'coffee', 'snack', //
    'snacks', 'food', 'restaurant', 'singara', 'burger', 'pizza', 'biryani',
    'চা', 'নাস্তা', 'খাবার', 'দুপুরের', 'রাতের', 'ভাত', 'সিঙ্গারা', 'কফি',
    'বিরিয়ানি', 'রেস্টুরেন্ট',
  ],
  'groceries': [
    'bazar', 'bazaar', 'grocery', 'groceries', 'vegetables', 'fish', //
    'meat', 'rice', 'egg', 'eggs', 'milk', 'বাজার', 'চাল', 'ডাল', 'সবজি',
    'মাছ', 'মাংস', 'ডিম', 'দুধ',
  ],
  'transport': [
    'rickshaw', 'bus', 'cng', 'uber', 'pathao', 'taxi', 'train', 'fuel', //
    'petrol', 'fare', 'transport', 'রিকশা', 'রিক্সা', 'বাস', 'সিএনজি',
    'উবার', 'পাঠাও', 'ট্রেন', 'যাতায়াত', 'পেট্রোল',
  ],
  'shopping': [
    'shopping', 'clothes', 'shirt', 'shoes', 'dress', 'কেনাকাটা', 'জামা', //
    'কাপড়', 'জুতা',
  ],
  'bills': [
    'electricity', 'gas', 'water', 'bill', 'utility', 'বিদ্যুৎ', 'কারেন্ট', //
    'গ্যাস', 'পানি', 'বিল',
  ],
  'rent': ['rent', 'ভাড়া'],
  'health': [
    'medicine', 'doctor', 'hospital', 'pharmacy', 'ওষুধ', 'ঔষধ', 'ডাক্তার', //
    'হাসপাতাল',
  ],
  'education': [
    'book', 'books', 'tuition', 'school', 'college', 'course', 'fee', //
    'fees', 'বই', 'টিউশন', 'স্কুল', 'কলেজ', 'ফি',
  ],
  'entertainment': ['movie', 'cinema', 'game', 'netflix', 'সিনেমা', 'মুভি'],
  'mobile': [
    'recharge', 'internet', 'data', 'mb', 'flexiload', 'wifi', 'রিচার্জ', //
    'ইন্টারনেট', 'ফ্লেক্সিলোড',
  ],
  'gifts': ['gift', 'gifts', 'donation', 'উপহার', 'গিফট', 'দান'],
  'salary': ['salary', 'বেতন'],
  'business': ['business', 'sale', 'sales', 'ব্যবসা', 'বিক্রি'],
};

// ----------------------------------------------------------- numbers --

/// The first number phrase ("1.5k", "45 thousand", "দুই হাজার পাঁচ শ") and
/// the word positions it used (with a "taka" next to it).
(Money?, Set<int>) _findAmount(List<String> words) {
  for (var i = 0; i < words.length; i++) {
    final first = _numberAt(words, i);
    if (first == null) continue;
    var total = 0.0;
    var current = first.$1;
    var j = i + first.$2;
    while (j < words.length) {
      final mult = _lex.multipliers[words[j]];
      if (mult != null) {
        if (mult >= 1000) {
          total += (current == 0 ? 1.0 : current) * mult;
          current = 0;
        } else {
          current = (current == 0 ? 1.0 : current) * mult;
        }
        j++;
        continue;
      }
      // "two thousand five hundred": keep adding smaller parts.
      final next = _numberAt(words, j);
      if (next != null && (total > 0 || current >= 100)) {
        current += next.$1;
        j += next.$2;
        continue;
      }
      break;
    }
    total += current;
    final minor = (total * 100).round();
    if (minor <= 0) continue;
    final used = {for (var k = i; k < j; k++) k};
    if (j < words.length && _lex.currency.contains(words[j])) used.add(j);
    if (i > 0 && _lex.currency.contains(words[i - 1])) used.add(i - 1);
    return (Money(minor), used);
  }
  return (null, <int>{});
}

/// A number starting at word [i]: its value and how many words it took.
(double, int)? _numberAt(List<String> words, int i) {
  final w = words[i];
  final k = RegExp(r'^(\d+(?:\.\d+)?)k$').firstMatch(w);
  if (k != null) return (double.parse(k[1]!) * 1000, 1);
  final n = double.tryParse(w);
  if (n != null) return (n, 1);
  final unit = _lex.units[w];
  if (unit == null) return null;
  // "twenty five" → 25
  if (unit >= 20 && unit % 10 == 0 && i + 1 < words.length) {
    final next = _lex.units[words[i + 1]];
    if (next != null && next > 0 && next < 10) {
      return ((unit + next).toDouble(), 2);
    }
  }
  return (unit.toDouble(), 1);
}

// ---------------------------------------------------------- category --

Category? _matchCategory(
  String text,
  List<String> words,
  List<Category> categories,
  String Function(Category) names,
  CategoryKind kind,
) {
  final pool = categories.where((c) => c.kind == kind && !c.isArchived);
  // 1. A category's own name said out loud (longest match wins).
  Category? best;
  var bestLength = 0;
  for (final c in pool) {
    for (final name in {names(c), c.name}) {
      final n = _unify(name.toLowerCase().trim());
      if (n.length < 2 || n.length <= bestLength) continue;
      final hit = n.contains(' ') ? text.contains(n) : words.contains(n);
      if (hit) {
        best = c;
        bestLength = n.length;
      }
    }
  }
  if (best != null) return best;
  // 2. Keywords for built-ins (the first keyword spoken wins).
  for (final w in words) {
    for (final c in pool) {
      if (_lex.keywords[c.systemKey]?.contains(w) ?? false) return c;
    }
  }
  return null;
}
