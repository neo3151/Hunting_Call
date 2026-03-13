import 'package:outcall/core/utils/app_logger.dart';

/// Advanced profanity and inappropriate content filter for user-facing text.
///
/// Multi-layer detection system:
/// 1. **Blocklist matching** — Comprehensive English + multi-language terms
/// 2. **Normalisation** — Defeats leet-speak, homoglyphs, spacing, symbols
/// 3. **Repeated character collapsing** — Catches "fuuuuck", "shiiiit"
/// 4. **Reversed text detection** — Catches "rekcuf", "reltih"
/// 5. **Phonetic matching** — Soundex algorithm catches "phaq", "fvck"
/// 6. **False-positive whitelist** — Prevents blocking "Dickens", "Scunthorpe"
/// 7. **Remote blocklist** — Dynamically updated via Firebase Remote Config
class ProfanityFilter {
  ProfanityFilter._();

  // ── Core Blocklist ────────────────────────────────────────────────

  static const _blockedTerms = <String>[
    // Profanity (English)
    'fuck', 'shit', 'ass', 'bitch', 'bastard', 'dick', 'cock', 'pussy', 'cunt',
    'piss', 'whore', 'slut', 'fag', 'faggot', 'wanker', 'twat', 'bollocks',
    'arse', 'arsehole', 'asshole', 'motherfucker', 'fucker', 'bullshit',
    'dumbass', 'jackass', 'dipshit', 'shithead', 'douchebag', 'douche',

    // Racial / ethnic slurs
    'nigger', 'nigga', 'wetback', 'spic', 'chink', 'gook', 'kike',
    'beaner', 'coon', 'raghead', 'towelhead', 'darkie',

    // Sexual / explicit
    'penis', 'vagina', 'dildo', 'boner', 'tits', 'boobs', 'blowjob',
    'handjob', 'cumshot', 'porn', 'hentai', 'xxx',
    'horny', 'milf', 'thot', 'nudes', 'onlyfans',

    // Hate / extremism
    'nazi', 'hitler', 'hilter', 'heil', 'kkk', 'white power',
    'white supremac', 'aryan', 'jihad', 'terrorist', 'genocide',

    // Violence
    'rapist', 'rape', 'serial kill', 'slaughter', 'torture',

    // Ableist / derogatory
    'retard', 'retarded', 'spaz', 'tard', 'mongoloid',

    // Troll / edgy
    'deez nuts', 'ligma', 'kys', 'kill yourself', 'go die',

    // Spanish
    'puta', 'mierda', 'cabron', 'pendejo', 'chingada', 'verga',
    'culero', 'marica', 'joto', 'pinche',

    // French
    'putain', 'merde', 'salaud', 'enculer', 'connard', 'salope',
    'bordel', 'nique',

    // German
    'schlampe', 'arschloch', 'wichser', 'hurensohn', 'fotze',
    'schwuchtel', 'missgeburt',

    // Portuguese
    'caralho', 'porra', 'buceta', 'viado', 'foda',
  ];

  /// Words that contain blocked substrings but are innocent.
  static const _whitelist = <String>{
    // Contains 'ass'
    'assassin', 'assault', 'bass', 'class', 'grass', 'brass',
    'compass', 'embassy', 'harass', 'lasso', 'mass', 'pass',
    'sassafras', 'trespass', 'morass', 'classic', 'cassette',
    // Contains 'dick'
    'dickens', 'dickson', 'benedict', 'addiction', 'diction', 'predict',
    'verdict', 'dictate', 'dictionary', 'edict',
    // Contains 'cock'
    'cockatoo', 'cockatiel', 'peacock', 'hancock', 'woodcock',
    'cockpit', 'cockerel', 'cocktail',
    // Contains 'tit'
    'title', 'titan', 'constitute', 'destitute', 'institute',
    'petition', 'competition', 'appetite', 'restitution', 'titmouse',
    // Contains 'cum'
    'circumvent', 'circumference', 'document', 'accumulate', 'cucumber',
    // Contains 'cunt'
    'scunthorpe',
    // Contains 'nig'
    'night', 'knight', 'nigel',
    // Contains 'hoe'
    'shoe', 'shoelace', 'horseshoe',
    // Contains 'rape'
    'grape', 'drape', 'scrape', 'trapeze',
    // Contains 'hit'
    'hitch', 'stitch', 'hitchhike', 'whiteboard', 'white',
    // Contains 'hell'
    'shell', 'hello', 'michelle', 'seashell',
    // Contains 'damn'
    'amsterdam',
    // Contains 'homo'
    'homogeneous', 'homologue',
    // Contains 'anus'
    'janus', 'uranus', 'manuscript', 'manual',
    // Hunting-specific whitelisted terms
    'hunter', 'hunting', 'cockade', 'cockspur',
  };

  /// Extra terms loaded from Firebase Remote Config at runtime.
  static List<String> _remoteBlockedTerms = [];

  /// Load additional blocked terms from Remote Config.
  static void loadRemoteTerms(List<String> terms) {
    _remoteBlockedTerms = terms;
    _rebuildPatterns();
    AppLogger.d('🔄 ProfanityFilter: loaded ${terms.length} remote terms');
  }

  // ── Pattern Building ──────────────────────────────────────────────

  static List<String> _allTerms = [];
  static List<RegExp> _patterns = [];

  static void _rebuildPatterns() {
    _allTerms = [..._blockedTerms, ..._remoteBlockedTerms];
    _patterns = _allTerms.map((term) {
      final escaped = RegExp.escape(term);
      return RegExp(escaped, caseSensitive: false);
    }).toList(growable: false);
  }

  // Initialise patterns on first access
  static bool _initialised = false;
  static void _ensureInitialised() {
    if (!_initialised) {
      _rebuildPatterns();
      _initialised = true;
    }
  }

  // ── Unicode Homoglyph Map ─────────────────────────────────────────

  /// Maps visually similar Unicode characters to their Latin equivalents.
  /// Covers Cyrillic, Greek, and common lookalikes.
  static const _homoglyphs = <String, String>{
    // Cyrillic → Latin
    'а': 'a', 'А': 'A', 'в': 'b', 'В': 'B', 'с': 'c', 'С': 'C',
    'е': 'e', 'Е': 'E', 'ё': 'e', 'Ё': 'E', 'н': 'h', 'Н': 'H',
    'і': 'i', 'І': 'I', 'к': 'k', 'К': 'K', 'м': 'm', 'М': 'M',
    'о': 'o', 'О': 'O', 'р': 'p', 'Р': 'P', 'т': 't', 'Т': 'T',
    'х': 'x', 'Х': 'X', 'у': 'y', 'У': 'Y',
    // Greek → Latin
    'α': 'a', 'Α': 'A', 'β': 'b', 'Β': 'B', 'ε': 'e', 'Ε': 'E',
    'η': 'n', 'Η': 'H', 'ι': 'i', 'Ι': 'I', 'κ': 'k', 'Κ': 'K',
    'ο': 'o', 'Ο': 'O', 'ρ': 'p', 'Ρ': 'P', 'τ': 't', 'Τ': 'T',
    'υ': 'u', 'Υ': 'Y', 'χ': 'x', 'Χ': 'X',
    // Fullwidth Latin
    'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e', 'ｆ': 'f',
    'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j', 'ｋ': 'k', 'ｌ': 'l',
    'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o', 'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r',
    'ｓ': 's', 'ｔ': 't', 'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x',
    'ｙ': 'y', 'ｚ': 'z',
  };

  // ── Soundex (Phonetic Matching) ───────────────────────────────────

  /// Generates a Soundex code for the given word.
  /// Soundex maps similar-sounding words to the same 4-character code.
  static String _soundex(String word) {
    if (word.isEmpty) return '';

    final upper = word.toUpperCase();
    final buffer = StringBuffer(upper[0]);

    const codeMap = {
      'B': '1', 'F': '1', 'P': '1', 'V': '1',
      'C': '2', 'G': '2', 'J': '2', 'K': '2', 'Q': '2', 'S': '2',
      'X': '2', 'Z': '2',
      'D': '3', 'T': '3',
      'L': '4',
      'M': '5', 'N': '5',
      'R': '6',
    };

    var lastCode = codeMap[upper[0]] ?? '0';

    for (var i = 1; i < upper.length && buffer.length < 4; i++) {
      final code = codeMap[upper[i]];
      if (code != null && code != lastCode) {
        buffer.write(code);
      }
      lastCode = code ?? '0';
    }

    // Pad to 4 characters
    while (buffer.length < 4) {
      buffer.write('0');
    }

    return buffer.toString();
  }

  /// Pre-computed Soundex codes for blocked terms (only single words).
  static final Map<String, String> _blockedSoundexCodes = _buildSoundexCodes();

  static Map<String, String> _buildSoundexCodes() {
    final codes = <String, String>{};
    for (final term in _blockedTerms) {
      // Only compute Soundex for single words (no spaces)
      if (!term.contains(' ') && term.length >= 3) {
        codes[term] = _soundex(term);
      }
    }
    return codes;
  }

  // ── Public API ────────────────────────────────────────────────────

  /// Returns `true` if [text] contains any blocked term.
  static bool containsProfanity(String? text) {
    if (text == null || text.isEmpty) return false;
    _ensureInitialised();

    // Check whitelist first — if the whole name is whitelisted, allow it
    if (_isWhitelisted(text)) return false;

    // Layer 0: Direct lowercase check (catches 'kkk', 'nazi', etc. before
    // the normaliser's repeated-character collapsing strips them)
    final lower = text.toLowerCase();
    for (final pattern in _patterns) {
      if (pattern.hasMatch(lower)) {
        if (!_isWhitelisted(lower)) return true;
      }
    }

    // Layer 1: Normalised blocklist matching
    final normalised = _normalise(text);
    for (final pattern in _patterns) {
      if (pattern.hasMatch(normalised)) {
        // Double-check against whitelist for the normalised form
        if (!_isWhitelisted(normalised)) return true;
      }
    }

    // Layer 2: Reversed text detection
    final reversed = String.fromCharCodes(normalised.runes.toList().reversed);
    for (final pattern in _patterns) {
      if (pattern.hasMatch(reversed)) return true;
    }

    // Layer 3: Phonetic matching (Soundex)
    if (_checkPhonetic(normalised)) return true;

    return false;
  }

  /// Returns the first matched blocked term found in [text], or `null`.
  static String? getFirstMatch(String? text) {
    if (text == null || text.isEmpty) return null;
    _ensureInitialised();

    if (_isWhitelisted(text)) return null;

    final normalised = _normalise(text);

    // Direct match
    for (var i = 0; i < _patterns.length; i++) {
      if (_patterns[i].hasMatch(normalised) && !_isWhitelisted(normalised)) {
        return _allTerms[i];
      }
    }

    // Reversed match
    final reversed = String.fromCharCodes(normalised.runes.toList().reversed);
    for (var i = 0; i < _patterns.length; i++) {
      if (_patterns[i].hasMatch(reversed)) {
        return '${_allTerms[i]} (reversed)';
      }
    }

    // Phonetic match
    final phoneticMatch = _getPhoneticMatch(normalised);
    if (phoneticMatch != null) return '$phoneticMatch (phonetic)';

    return null;
  }

  /// Cleans a name by replacing blocked content with the fallback.
  static String cleanName(String input, {String fallback = 'Hunter'}) {
    if (containsProfanity(input)) {
      AppLogger.d('⚠️ ProfanityFilter: blocked name "$input"');
      return fallback;
    }
    return input;
  }

  // ── White-list Check ──────────────────────────────────────────────

  static bool _isWhitelisted(String text) {
    final lower = text.toLowerCase();
    return _whitelist.any((safe) => lower == safe || lower.contains(safe));
  }

  // ── Phonetic Checks ───────────────────────────────────────────────

  /// Checks if any word in [text] phonetically matches a blocked term.
  static bool _checkPhonetic(String text) {
    return _getPhoneticMatch(text) != null;
  }

  static String? _getPhoneticMatch(String text) {
    // Split into words and check each
    final words = text.toLowerCase().split(RegExp(r'[^a-z]+'));
    for (final word in words) {
      if (word.length < 3) continue;
      final code = _soundex(word);
      for (final entry in _blockedSoundexCodes.entries) {
        if (code == entry.value) {
          // Make sure it's not a whitelisted word
          if (!_whitelist.contains(word)) {
            return entry.key;
          }
        }
      }
    }
    return null;
  }

  // ── Normalisation Pipeline ────────────────────────────────────────

  /// Multi-step normalisation to defeat common evasion tricks:
  /// 1. Strip zero-width / invisible Unicode characters
  /// 2. Replace Unicode homoglyphs (Cyrillic, Greek, fullwidth) → Latin
  /// 3. Leet-speak number/symbol → letter substitutions
  /// 4. Collapse repeated characters (3+ → 1)
  /// 5. Remove separators (spaces, dots, underscores, dashes)
  static String _normalise(String input) {
    final buffer = StringBuffer();

    // Step 1 + 2: Strip invisible chars and replace homoglyphs
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);

      // Skip zero-width / invisible characters
      if (rune >= 0x200B && rune <= 0x200D) continue; // Zero-width joiners
      if (rune == 0xFEFF) continue; // BOM
      if (rune >= 0x2060 && rune <= 0x2064) continue; // Invisible operators
      if (rune >= 0xFE00 && rune <= 0xFE0F) continue; // Variation selectors

      // Replace homoglyphs
      final replacement = _homoglyphs[char];
      if (replacement != null) {
        buffer.write(replacement);
      } else {
        buffer.write(char);
      }
    }

    var s = buffer.toString();

    // Step 3: Leet-speak substitutions
    s = s
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('8', 'b')
        .replaceAll('9', 'g')
        .replaceAll('@', 'a')
        .replaceAll('\$', 's')
        .replaceAll('!', 'i')
        .replaceAll('(', 'c')
        .replaceAll('+', 't')
        .replaceAll('|', 'l')
        .replaceAll('}{', 'h');

    // Step 4: Collapse repeated characters (3+ of the same → 1)
    s = s.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
      (m) => m.group(1)!,
    );

    // Step 5: Remove separators
    s = s.replaceAll(RegExp(r'[\s._\-*~`]+'), '');

    return s;
  }
}
