import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A rich, high-performance mathematics and physics formula parser and renderer.
/// Converts LaTeX, plain text formulas, Greek letter names, superscripts, subscripts,
/// square roots, fractions, and physics constants into clean, readable notation.
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final TextStyle effectiveStyle = defaultTextStyle.style.merge(
      style ?? GoogleFonts.inter(
        fontFamilyFallback: const ['Inter', 'Roboto', 'sans-serif'],
      ),
    );

    // If text is empty, return empty text
    if (text.trim().isEmpty) {
      return Text('', style: effectiveStyle, textAlign: textAlign);
    }

    final List<InlineSpan> spans = parseMathToSpans(text, effectiveStyle);

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans),
    );
  }

  /// Converts a raw question, option, or explanation string into structured [InlineSpan]s
  static List<InlineSpan> parseMathToSpans(String rawText, TextStyle baseStyle) {
    // 1. If text contains explicit LaTeX delimiters ($...$, $$...$$, \(...\), \[...\])
    final delimiterRegex = RegExp(
      r'\$\$([\s\S]+?)\$\$|'
      r'\$([\s\S]+?)\$|'
      r'\\\[([\s\S]+?)\\\]|'
      r'\\\(([\s\S]+?)\\\)|'
      r'\\\\\[([\s\S]+?)\\\\\]|'
      r'\\\\\(([\s\S]+?)\\\\\)',
    );

    if (delimiterRegex.hasMatch(rawText)) {
      final List<InlineSpan> result = [];
      int lastIndex = 0;

      for (final match in delimiterRegex.allMatches(rawText)) {
        if (match.start > lastIndex) {
          final plainSegment = rawText.substring(lastIndex, match.start);
          result.addAll(_parseTextSegment(plainSegment, baseStyle));
        }

        final mathExpr = match.group(1) ??
            match.group(2) ??
            match.group(3) ??
            match.group(4) ??
            match.group(5) ??
            match.group(6) ??
            '';

        if (mathExpr.isNotEmpty) {
          final formatted = formatMathString(mathExpr);
          result.add(TextSpan(
            text: formatted,
            style: baseStyle.copyWith(
              fontFamilyFallback: const ['Inter', 'Roboto', 'sans-serif'],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ));
        }
        lastIndex = match.end;
      }

      if (lastIndex < rawText.length) {
        result.addAll(_parseTextSegment(rawText.substring(lastIndex), baseStyle));
      }

      return result;
    }

    // 2. Plain text (may contain inline formulas, Greek variable names, exponents, etc.)
    return _parseTextSegment(rawText, baseStyle);
  }

  /// Parses text that might contain formulas mixed with natural English sentences
  static List<InlineSpan> _parseTextSegment(String segment, TextStyle baseStyle) {
    if (segment.isEmpty) return [];

    // Format formulas, Greek letters, exponents, subscripts, operators throughout the text
    final formatted = formatMathString(segment);

    return [
      TextSpan(
        text: formatted,
        style: baseStyle,
      ),
    ];
  }

  /// Formats raw math expressions (e.g. `s = pi*r^2 * (theta / 360)`) into clear symbols
  static String formatMathString(String input) {
    if (input.isEmpty) return input;
    String s = input;

    // A. Strip surrounding LaTeX tags and clean escapes
    s = s.replaceAll(r'\\', r'\');
    s = s.replaceAll(r'\left(', '(').replaceAll(r'\right)', ')');
    s = s.replaceAll(r'\left[', '[').replaceAll(r'\right]', ']');
    s = s.replaceAll(r'\left\{', '{').replaceAll(r'\right\}', '}');
    s = s.replaceAll(r'\{', '{').replaceAll(r'\}', '}');
    s = s.replaceAll(r'\,', ' ').replaceAll(r'\;', ' ').replaceAll(r'\quad', '  ').replaceAll(r'\qquad', '   ');

    // B. Strip LaTeX text and font wrappers
    s = s.replaceAllMapped(RegExp(r'\\(?:text|mathrm|mathbf|mathit|textbf|textrm|mathbb|mathcal)\{([^}]+)\}'), (m) => m.group(1) ?? '');

    // C. Common Math Functions (remove leading backslash)
    s = s.replaceAll(r'\log', 'log');
    s = s.replaceAll(r'\ln', 'ln');
    s = s.replaceAll(r'\sin', 'sin');
    s = s.replaceAll(r'\cos', 'cos');
    s = s.replaceAll(r'\tan', 'tan');
    s = s.replaceAll(r'\cot', 'cot');
    s = s.replaceAll(r'\sec', 'sec');
    s = s.replaceAll(r'\csc', 'csc');
    s = s.replaceAll(r'\arcsin', 'arcsin');
    s = s.replaceAll(r'\arccos', 'arccos');
    s = s.replaceAll(r'\arctan', 'arctan');
    s = s.replaceAll(r'\sinh', 'sinh');
    s = s.replaceAll(r'\cosh', 'cosh');
    s = s.replaceAll(r'\tanh', 'tanh');
    s = s.replaceAll(r'\exp', 'exp');
    s = s.replaceAll(r'\lim', 'lim');
    s = s.replaceAll(r'\det', 'det');
    s = s.replaceAll(r'\gcd', 'gcd');
    s = s.replaceAll(r'\min', 'min');
    s = s.replaceAll(r'\max', 'max');
    s = s.replaceAll(r'\sup', 'sup');
    s = s.replaceAll(r'\inf', 'inf');

    // D. Vector & Accent Notations
    s = s.replaceAllMapped(RegExp(r'\\vec\{([^}]+)\}'), (m) => '${m.group(1)}⃗');
    s = s.replaceAllMapped(RegExp(r'\\hat\{i\}'), (m) => 'î');
    s = s.replaceAllMapped(RegExp(r'\\hat\{j\}'), (m) => 'ĵ');
    s = s.replaceAllMapped(RegExp(r'\\hat\{k\}'), (m) => 'k̂');
    s = s.replaceAllMapped(RegExp(r'\\hat\{([^}]+)\}'), (m) => '${m.group(1)}̂');
    s = s.replaceAllMapped(RegExp(r'\\bar\{([^}]+)\}'), (m) => '${m.group(1)}̄');
    s = s.replaceAllMapped(RegExp(r'\\dot\{([^}]+)\}'), (m) => '${m.group(1)}̇');
    s = s.replaceAllMapped(RegExp(r'\\ddot\{([^}]+)\}'), (m) => '${m.group(1)}̈');

    // E. Handle Fractions: \frac{a}{b} -> (a / b) or a/b
    s = s.replaceAllMapped(RegExp(r'\\(?:frac|dfrac)\{([^}]+)\}\{([^}]+)\}'), (m) {
      final num = m.group(1)!.trim();
      final den = m.group(2)!.trim();
      if (num == '1' && den == '2') return '½';
      if (num == '1' && den == '3') return '⅓';
      if (num == '2' && den == '3') return '⅔';
      if (num == '1' && den == '4') return '¼';
      if (num == '3' && den == '4') return '¾';
      if (num.length <= 3 && den.length <= 3 && !num.contains(' ') && !den.contains(' ')) {
        return '$num/$den';
      }
      return '($num / $den)';
    });

    // F. Square Roots: \sqrt[3]{x} -> ∛(x), \sqrt{x} -> √(x), sqrt(x) -> √(x)
    s = s.replaceAllMapped(RegExp(r'\\sqrt\[3\]\{([^}]+)\}'), (m) => '∛(${m.group(1)})');
    s = s.replaceAllMapped(RegExp(r'\\sqrt\[4\]\{([^}]+)\}'), (m) => '∜(${m.group(1)})');
    s = s.replaceAllMapped(RegExp(r'\\sqrt\{([^}]+)\}'), (m) => '√(${m.group(1)})');
    s = s.replaceAllMapped(RegExp(r'\bsqrt\(([^)]+)\)'), (m) => '√(${m.group(1)})');
    s = s.replaceAll(r'\sqrt', '√');

    // G. LaTeX Symbols & Relations
    s = s.replaceAll(r'\times', '×');
    s = s.replaceAll(r'\cdot', '·');
    s = s.replaceAll(r'\div', '÷');
    s = s.replaceAll(r'\pm', '±');
    s = s.replaceAll(r'\mp', '∓');
    s = s.replaceAll(r'\le', '≤').replaceAll(r'\leq', '≤');
    s = s.replaceAll(r'\ge', '≥').replaceAll(r'\geq', '≥');
    s = s.replaceAll(r'\neq', '≠').replaceAll(r'\ne', '≠');
    s = s.replaceAll(r'\approx', '≈').replaceAll(r'\sim', '≈');
    s = s.replaceAll(r'\equiv', '≡');
    s = s.replaceAll(r'\propto', '∝');
    s = s.replaceAll(r'\to', '→').replaceAll(r'\rightarrow', '→');
    s = s.replaceAll(r'\leftarrow', '←');
    s = s.replaceAll(r'\leftrightarrow', '↔');
    s = s.replaceAll(r'\Rightarrow', '⇒');
    s = s.replaceAll(r'\Leftrightarrow', '⇔');
    s = s.replaceAll(r'\infty', '∞');
    s = s.replaceAll(r'\int', '∫');
    s = s.replaceAll(r'\sum', '∑');
    s = s.replaceAll(r'\prod', '∏');
    s = s.replaceAll(r'\partial', '∂');
    s = s.replaceAll(r'\nabla', '∇');
    s = s.replaceAll(r'\degree', '°').replaceAll(r'^\circ', '°').replaceAll(r'\circ', '°');

    // H. Greek Letters (LaTeX Commands)
    s = s.replaceAll(r'\pi', 'π').replaceAll(r'\Pi', 'Π');
    s = s.replaceAll(r'\theta', 'θ').replaceAll(r'\Theta', 'Θ');
    s = s.replaceAll(r'\alpha', 'α').replaceAll(r'\Alpha', 'Α');
    s = s.replaceAll(r'\beta', 'β').replaceAll(r'\Beta', 'Β');
    s = s.replaceAll(r'\gamma', 'γ').replaceAll(r'\Gamma', 'Γ');
    s = s.replaceAll(r'\lambda', 'λ').replaceAll(r'\Lambda', 'Λ');
    s = s.replaceAll(r'\delta', 'δ').replaceAll(r'\Delta', 'Δ');
    s = s.replaceAll(r'\epsilon', 'ε').replaceAll(r'\varepsilon', 'ε');
    s = s.replaceAll(r'\mu', 'μ');
    s = s.replaceAll(r'\omega', 'ω').replaceAll(r'\Omega', 'Ω');
    s = s.replaceAll(r'\rho', 'ρ');
    s = s.replaceAll(r'\sigma', 'σ').replaceAll(r'\Sigma', 'Σ');
    s = s.replaceAll(r'\tau', 'τ');
    s = s.replaceAll(r'\phi', 'φ').replaceAll(r'\Phi', 'Φ');
    s = s.replaceAll(r'\psi', 'ψ').replaceAll(r'\Psi', 'Ψ');
    s = s.replaceAll(r'\eta', 'η');
    s = s.replaceAll(r'\nu', 'ν');
    s = s.replaceAll(r'\zeta', 'ζ');
    s = s.replaceAll(r'\kappa', 'κ');
    s = s.replaceAll(r'\xi', 'ξ').replaceAll(r'\Xi', 'Ξ');

    // G. Plain Text Greek Word Conversions (Word Boundaries to avoid replacing English words)
    // Example: "theta" -> "θ", "pi" -> "π", "alpha" -> "α", "lambda" -> "λ"
    s = s.replaceAll(RegExp(r'\btheta\b', caseSensitive: false), 'θ');
    s = s.replaceAll(RegExp(r'\bpi\b', caseSensitive: false), 'π');
    s = s.replaceAll(RegExp(r'\balpha\b', caseSensitive: false), 'α');
    s = s.replaceAll(RegExp(r'\bbeta\b', caseSensitive: false), 'β');
    s = s.replaceAll(RegExp(r'\blambda\b', caseSensitive: false), 'λ');
    s = s.replaceAll(RegExp(r'\bgamma\b', caseSensitive: false), 'γ');
    s = s.replaceAll(RegExp(r'\bDelta\b'), 'Δ');
    s = s.replaceAll(RegExp(r'\bdelta\b'), 'δ');
    s = s.replaceAll(RegExp(r'\bmu\b', caseSensitive: false), 'μ');
    s = s.replaceAll(RegExp(r'\bomega\b', caseSensitive: false), 'ω');
    s = s.replaceAll(RegExp(r'\bOmega\b'), 'Ω');
    s = s.replaceAll(RegExp(r'\bphi\b', caseSensitive: false), 'φ');
    s = s.replaceAll(RegExp(r'\bpsi\b', caseSensitive: false), 'ψ');
    s = s.replaceAll(RegExp(r'\brho\b', caseSensitive: false), 'ρ');
    s = s.replaceAll(RegExp(r'\bsigma\b'), 'σ');
    s = s.replaceAll(RegExp(r'\bSigma\b'), 'Σ');
    s = s.replaceAll(RegExp(r'\btau\b', caseSensitive: false), 'τ');
    s = s.replaceAll(RegExp(r'\bepsilon\b', caseSensitive: false), 'ε');
    s = s.replaceAll(RegExp(r'\binfinity\b', caseSensitive: false), '∞');

    // H. Plain Text Relational & Math Operators
    s = s.replaceAll('<=', '≤');
    s = s.replaceAll('>=', '≥');
    s = s.replaceAll('!=', '≠');
    s = s.replaceAll('<>', '≠');
    s = s.replaceAll('+/-', '±');
    s = s.replaceAll('+-', '±');
    s = s.replaceAll('~=', '≈');
    s = s.replaceAll('=~', '≈');
    s = s.replaceAll('-->', '→');
    s = s.replaceAll('->', '→');
    s = s.replaceAll('<--', '←');
    s = s.replaceAll('<-', '←');
    s = s.replaceAll('<->', '↔');
    s = s.replaceAll('<-->', '↔');

    // I. Multiplication Asterisks in Math Formats
    // e.g. `2*pi*r` -> `2 · π · r` or `pi*r^2 * (theta / 360)` -> `π · r² · (θ / 360)`
    s = s.replaceAll('**', '^'); // Python style exponent
    // Convert `*` with spaces around it to middle dot `·`
    s = s.replaceAll(RegExp(r'\s*\*\s*'), ' · ');

    // Clean multiple dots if any
    s = s.replaceAll(RegExp(r'(·\s*)+·'), '·');

    // J. Degrees notation after angles (e.g. `360 deg` -> `360°`, `180 deg` -> `180°`)
    s = s.replaceAllMapped(RegExp(r'(\d+)\s*(?:deg|degrees|degree)\b', caseSensitive: false), (m) => '${m.group(1)}°');

    // K. Exponents & Superscripts Parser:
    // Handles expressions like `r^2`, `x^3`, `10^-11`, `10^{8}`, `m/s^2`, `kg*m/s^2`
    s = _convertExponentsToSuperscripts(s);

    // L. Subscripts Parser:
    // Handles expressions like `v_avg`, `f_s`, `f_k`, `m_1`, `m_2`, `F_net`, `x_0`, `T_{initial}`
    s = _convertSubscripts(s);

    // M. Spacing refinement for parentheses and math operators
    s = s.replaceAllMapped(RegExp(r'\(\s+'), (m) => '(');
    s = s.replaceAllMapped(RegExp(r'\s+\)'), (m) => ')');

    return s;
  }

  /// Converts exponent notations like `^2`, `^{2x+1}`, `^-1`, `^3`, `^n` into Unicode superscripts
  static String _convertExponentsToSuperscripts(String text) {
    const Map<String, String> supMap = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
      '=': '⁼',
      '(': '⁽',
      ')': '⁾',
      '/': 'ᐟ',
      '⁄': 'ᐟ',
      '.': '˙',
      ',': '﹐',
      'a': 'ᵃ',
      'b': 'ᵇ',
      'c': 'ᶜ',
      'd': 'ᵈ',
      'e': 'ᵉ',
      'f': 'ᶠ',
      'g': 'ᵍ',
      'h': 'ʰ',
      'i': 'ⁱ',
      'j': 'ʲ',
      'k': 'ᵏ',
      'l': 'ˡ',
      'm': 'ᵐ',
      'n': 'ⁿ',
      'o': 'ᵒ',
      'p': 'ᵖ',
      'r': 'ʳ',
      's': 'ˢ',
      't': 'ᵗ',
      'u': 'ᵘ',
      'v': 'ᵛ',
      'w': 'ʷ',
      'x': 'ˣ',
      'y': 'ʸ',
      'z': 'ᶻ',
      'A': 'ᴬ',
      'B': 'ᴮ',
      'D': 'ᴰ',
      'E': 'ᴱ',
      'G': 'ᴳ',
      'H': 'ᴴ',
      'I': 'ᴵ',
      'J': 'ᴶ',
      'K': 'ᴷ',
      'L': 'ᴸ',
      'M': 'ᴹ',
      'N': 'ᴺ',
      'O': 'ᴼ',
      'P': 'ᴾ',
      'R': 'ᴿ',
      'T': 'ᵀ',
      'U': 'ᵁ',
      'V': 'ⱽ',
      'W': 'ᵂ',
    };

    // 1. Bracketed exponents: `^{...}`
    String res = text.replaceAllMapped(RegExp(r'\^\{([^}]+)\}'), (match) {
      final inner = match.group(1) ?? '';
      final buffer = StringBuffer();
      for (int i = 0; i < inner.length; i++) {
        final ch = inner[i];
        buffer.write(supMap[ch] ?? ch);
      }
      return buffer.toString();
    });

    // 2. Negative signed integer exponents: `^-1`, `^-2`, `^-11`
    res = res.replaceAllMapped(RegExp(r'\^(-?\d+)'), (match) {
      final inner = match.group(1) ?? '';
      final buffer = StringBuffer();
      for (int i = 0; i < inner.length; i++) {
        final ch = inner[i];
        buffer.write(supMap[ch] ?? ch);
      }
      return buffer.toString();
    });

    // 3. Single character exponents: `^2`, `^3`, `^n`, `^x`, `^+`
    res = res.replaceAllMapped(RegExp(r'\^([0-9a-zA-Z\+\-])'), (match) {
      final ch = match.group(1) ?? '';
      return supMap[ch] ?? '^$ch';
    });

    return res;
  }

  /// Converts subscript notations like `_0`, `_1`, `_2`, `_avg`, `_{net}` into Unicode subscripts
  static String _convertSubscripts(String text) {
    const Map<String, String> subMap = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
      '+': '₊',
      '-': '₋',
      '=': '₌',
      '(': '₍',
      ')': '₎',
      'a': 'ₐ',
      'e': 'ₑ',
      'h': 'ₕ',
      'i': 'ᵢ',
      'j': 'ⱼ',
      'k': 'ₖ',
      'l': 'ₗ',
      'm': 'ₘ',
      'n': 'ₙ',
      'o': 'ₒ',
      'p': 'ₚ',
      'r': 'ᵣ',
      's': 'ₛ',
      't': 'ₜ',
      'u': 'ᵤ',
      'v': 'ᵥ',
      'x': 'ₓ',
    };

    // 1. Bracketed subscripts: `_{...}`
    String res = text.replaceAllMapped(RegExp(r'\_\{([^}]+)\}'), (match) {
      final inner = match.group(1) ?? '';
      final buffer = StringBuffer();
      bool allSub = true;
      for (int i = 0; i < inner.length; i++) {
        final ch = inner[i];
        if (subMap.containsKey(ch)) {
          buffer.write(subMap[ch]);
        } else {
          allSub = false;
          break;
        }
      }
      if (allSub && buffer.isNotEmpty) {
        return buffer.toString();
      }
      return '_($inner)';
    });

    // 2. Standard common word subscripts: `_avg`, `_max`, `_min`, `_net`, `_in`, `_out`, `_eff`, `_tot`, `_rms`
    const commonSubscripts = {
      'avg': 'ₐᵥᵧ',
      'max': 'ₘₐₓ',
      'min': 'ₘᵢₙ',
      'net': 'ₙₑₜ',
      'in': 'ᵢₙ',
      'out': 'ₒᵤₜ',
      'tot': 'ₜₒₜ',
      'rms': 'ᵣₘₛ',
    };

    for (final entry in commonSubscripts.entries) {
      res = res.replaceAll('_${entry.key}', entry.value);
    }

    // 3. Single digit or letter subscript: `_0`, `_1`, `_s`, `_k`, `_x`, `_y`, `_t`
    res = res.replaceAllMapped(RegExp(r'\_([0-9a-z\+\-])'), (match) {
      final ch = match.group(1) ?? '';
      return subMap[ch] ?? '_$ch';
    });

    return res;
  }
}
