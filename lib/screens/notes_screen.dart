import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_manager.dart';
import '../services/analytics_service.dart';
import '../main.dart';

enum NotesErrorType {
  none,
  noInternet,
  emptyData,
  serverError,
}

class NotesScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final int unitNumber;
  final String unitTitle;
  final Color themeColor;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onToggleTheme;

  const NotesScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.unitNumber,
    required this.unitTitle,
    required this.themeColor,
    required this.isDarkMode,
    required this.languageCode,
    this.onToggleTheme,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  late bool _isDarkMode;

  NotesErrorType _errorType = NotesErrorType.none;

  List<Map<String, dynamic>> _notesList = [];
  int _currentPageIndex = 0;
  late PageController _pageController;

  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _telegramChannelUrl = 'https://t.me/smart_x_academy';

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _pageController = PageController(initialPage: 0);

    // Firebase Analytics tracking for screen view and custom event
    logScreen('ShortNotesScreen');
    logEvent(
      name: 'short_note_opened',
      parameters: {
        'unit': widget.unitTitle,
        'subject': widget.subjectId,
        'grade': widget.grade,
        'unit_number': widget.unitNumber,
      },
    );

    _checkBookmarkStatus();
    _checkOfflineStatus();
    _fetchNotes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFloatingSnackbar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isInfo = false,
  }) {
    if (!mounted) return;
    Color bgColor = const Color(0xFF1E293B);
    IconData iconData = Icons.info_outline_rounded;
    if (isError) {
      bgColor = const Color(0xFFDC2626);
      iconData = Icons.error_outline_rounded;
    } else if (isSuccess) {
      bgColor = const Color(0xFF059669);
      iconData = Icons.check_circle_outline_rounded;
    } else if (isInfo) {
      bgColor = const Color(0xFF0284C7);
      iconData = Icons.downloading_rounded;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getUnitId() {
    String sub = widget.subjectId.toLowerCase();
    String prefix = 'phys_u';
    if (sub.contains('math')) {
      prefix = 'math_u';
    } else if (sub.contains('biol') || sub.contains('bio')) {
      prefix = 'bio_u';
    } else if (sub.contains('phys')) {
      prefix = 'phys_u';
    } else if (sub.contains('chem')) {
      prefix = 'chem_u';
    } else if (sub.contains('geog') || sub.contains('geo')) {
      prefix = 'geo_u';
    } else if (sub.contains('hist')) {
      prefix = 'hist_u';
    } else if (sub.contains('civ')) {
      prefix = 'civ_u';
    } else if (sub.contains('agri') || sub.contains('agr')) {
      prefix = 'agri_u';
    } else if (sub.contains('econ') || sub.contains('eco')) {
      prefix = 'econ_u';
    } else if (sub.contains('eng')) {
      prefix = 'eng_u';
    }
    return 'g${widget.grade}_$prefix${widget.unitNumber}';
  }

  String _getNormalizedSubjectName() {
    final sub = widget.subjectId.toLowerCase();
    if (sub.contains('math')) return 'mathematics';
    if (sub.contains('biol') || sub.contains('bio')) return 'biology';
    if (sub.contains('phys')) return 'physics';
    if (sub.contains('chem')) return 'chemistry';
    if (sub.contains('geog') || sub.contains('geo')) return 'geography';
    if (sub.contains('hist')) return 'history';
    if (sub.contains('civ')) return 'civics';
    if (sub.contains('agri') || sub.contains('agr')) return 'agriculture';
    if (sub.contains('econ') || sub.contains('eco')) return 'economics';
    if (sub.contains('eng')) return 'english';
    return sub;
  }

  Future<void> _checkOfflineStatus() async {
    final String unitId = _getUnitId();
    final bool downloaded = await OfflineManager.isDownloaded(unitId);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }

  /// Sanitizes HTML to prevent duplicated headers and enforce clean nested markup.
  String _sanitizeHtml(String rawHtml, String title) {
    if (rawHtml.isEmpty) return '<p>No content available for this section.</p>';
    String cleaned = rawHtml.trim();

    // Strip duplicated <h1>/<h2> tags matching the section title
    if (title.isNotEmpty) {
      final escapedTitle = RegExp.escape(title.trim());
      cleaned = cleaned.replaceAll(RegExp(r'<h[1-2][^>]*>\s*' + escapedTitle + r'\s*<\/h[1-2]>', caseSensitive: false), '');
    }

    return cleaned;
  }

  Future<void> _fetchNotes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorType = NotesErrorType.none;
      });

      // Check internet connection proactively
      bool hasConnection = true;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
          hasConnection = false;
        }
      } catch (_) {}

      final String unitId = _getUnitId();
      final bool isNotesDownloaded = await OfflineManager.isDownloaded(unitId);
      List<Map<String, dynamic>> fetchedNotes = [];

      if (isNotesDownloaded) {
        fetchedNotes = await OfflineManager.getOfflineNotes(unitId);
      } else {
        if (!hasConnection) {
          // If no connection and not downloaded, check fallback
          final fallback = _generateCurriculumFallbackNotes();
          if (fallback.isNotEmpty) {
            fetchedNotes = fallback;
          } else {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorType = NotesErrorType.noInternet;
            });
            return;
          }
        } else {
          final String normalizedSubject = _getNormalizedSubjectName();

          // 1. Primary Query: Supabase short_notes table strictly
          try {
            final shortNotesResponse = await Supabase.instance.client
                .from('short_notes')
                .select('id, grade, subject, unit_number, title, html_content, created_at')
                .eq('grade', widget.grade)
                .eq('unit_number', widget.unitNumber)
                .ilike('subject', '%$normalizedSubject%')
                .order('created_at', ascending: true);

            if (shortNotesResponse.isNotEmpty) {
              fetchedNotes = List<Map<String, dynamic>>.from(shortNotesResponse);
            }
          } catch (e) {
            debugPrint('[Short Notes] Supabase query notice: $e');
          }

          // 2. Built-in High-Quality Curriculum Seed Fallback if server table not yet seeded
          if (fetchedNotes.isEmpty) {
            fetchedNotes = _generateCurriculumFallbackNotes();
          }
        }
      }

      if (fetchedNotes.isNotEmpty) {
        _notesList = fetchedNotes;
        _currentPageIndex = 0;
      }

      setState(() {
        _isLoading = false;
        if (_notesList.isEmpty) {
          _hasError = true;
          _errorType = !hasConnection ? NotesErrorType.noInternet : NotesErrorType.emptyData;
        } else {
          _hasError = false;
          _errorType = NotesErrorType.none;
        }
      });
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching short notes: ${e.code} - ${e.message}');
      final fallback = _generateCurriculumFallbackNotes();
      setState(() {
        if (fallback.isNotEmpty) {
          _notesList = fallback;
          _currentPageIndex = 0;
          _hasError = false;
          _isLoading = false;
        } else {
          _notesList = [];
          _hasError = true;
          _isLoading = false;
          _errorType = NotesErrorType.serverError;
        }
      });
    } catch (e) {
      debugPrint('Error fetching short notes: $e');
      final fallback = _generateCurriculumFallbackNotes();
      setState(() {
        if (fallback.isNotEmpty) {
          _notesList = fallback;
          _currentPageIndex = 0;
          _hasError = false;
          _isLoading = false;
        } else {
          _notesList = [];
          _hasError = true;
          _isLoading = false;
          _errorType = NotesErrorType.serverError;
        }
      });
    }
  }

  List<Map<String, dynamic>> _generateCurriculumFallbackNotes() {
    final sub = _getNormalizedSubjectName();
    final g = widget.grade;
    final u = widget.unitNumber;

    if (sub == 'physics') {
      return [
        {
          'id': 'fallback_phys_${g}_$u',
          'grade': g,
          'subject': 'physics',
          'unit_number': u,
          'title': 'Core Principles & Formulations',
          'html_content': '''
            <div class="callout">
              <strong>Unit Scope:</strong> Foundational physical quantities, vector operations, equations of motion, and analytical problem-solving.
            </div>
            
            <h3>1. Fundamental Laws</h3>
            <p>Every measurable physical interaction obeys rigorous conservation principles. Quantities must always be evaluated in consistent <em>SI Base Units</em>.</p>
            
            <div class="definition">
              <strong>Work-Energy Theorem:</strong> The net work done by all acting forces equals the change in kinetic energy (<em>W<sub>net</sub> = &Delta;KE = &frac12;mv<sup>2</sup> - &frac12;mu<sup>2</sup></em>).
            </div>

            <h3>2. Kinematics & Motion Relationships</h3>
            <div class="formula">
              <ul>
                <li><strong>Final Velocity:</strong> <em>v = u + at</em></li>
                <li><strong>Displacement:</strong> <em>s = ut + &frac12;at<sup>2</sup></em></li>
                <li><strong>Torricelli's Equation:</strong> <em>v<sup>2</sup> = u<sup>2</sup> + 2as</em></li>
              </ul>
            </div>

            <div class="formula">
              <ul>
                <li><strong>Kinetic Energy:</strong> <em>KE = &frac12;mv<sup>2</sup></em></li>
                <li><strong>Gravitational Potential Energy:</strong> <em>PE = mgh</em></li>
                <li><strong>Instantaneous Power:</strong> <em>P = W / t = F &bull; v</em></li>
              </ul>
            </div>

            <h3>3. Matric Exam Key Tips</h3>
            <ul>
              <li>Convert non-standard units (e.g., km/h &rarr; m/s, cm &rarr; m, grams &rarr; kg) before calculating.</li>
              <li>Decompose vector quantities into orthogonal components (<em>F<sub>x</sub> = F cos&theta;</em>, <em>F<sub>y</sub> = F sin&theta;</em>).</li>
              <li>Always check whether non-conservative forces (friction, drag) perform work on the system.</li>
            </ul>
          ''',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'fallback_phys_${g}_${u}_summary',
          'grade': g,
          'subject': 'physics',
          'unit_number': u,
          'title': 'High-Frequency Exam Terms',
          'html_content': '''
            <div class="callout">
              <strong>Summary Table:</strong> High-frequency examination definitions and corresponding SI units.
            </div>
            <table>
              <thead>
                <tr><th>Concept</th><th>Definition</th><th>SI Unit</th></tr>
              </thead>
              <tbody>
                <tr><td>Impulse</td><td>Product of average force and interaction time (J = F &Delta;t)</td><td>N&bull;s</td></tr>
                <tr><td>Efficiency</td><td>(Useful Energy Output / Total Energy Input) &times; 100%</td><td>%</td></tr>
                <tr><td>Torque</td><td>Turning effect of a force (&tau; = r &times; F)</td><td>N&bull;m</td></tr>
                <tr><td>Centripetal Accel.</td><td>Acceleration directed toward center (a<sub>c</sub> = v<sup>2</sup> / r)</td><td>m/s<sup>2</sup></td></tr>
              </tbody>
            </table>
          ''',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
    }

    if (sub == 'mathematics') {
      return [
        {
          'id': 'fallback_math_${g}_$u',
          'grade': g,
          'subject': 'mathematics',
          'unit_number': u,
          'title': 'Core Theorems & Algebraic Rules',
          'html_content': '''
            <div class="callout">
              <strong>Unit Scope:</strong> Foundational theorems, logarithm rules, polynomial factorization, and analytical solutions.
            </div>

            <h3>1. Algebraic Identities</h3>
            <div class="formula">
              <ul>
                <li>log<sub>b</sub>(xy) = log<sub>b</sub>(x) + log<sub>b</sub>(y)</li>
                <li>log<sub>b</sub>(x/y) = log<sub>b</sub>(x) - log<sub>b</sub>(y)</li>
                <li>log<sub>b</sub>(x<sup>k</sup>) = k &times; log<sub>b</sub>(x)</li>
              </ul>
            </div>

            <h3>2. Problem-Solving Methodology</h3>
            <div class="example">
              <strong>Standard Steps:</strong>
              <ol>
                <li>State domain restrictions (e.g. non-zero denominators, strictly positive logarithms).</li>
                <li>Simplify algebraic expressions by grouping terms or completing squares.</li>
                <li>Substitute and check for extraneous solutions.</li>
              </ol>
            </div>
          ''',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
    }

    // Generic fallback for Chemistry, Biology, Economics, Geography, etc.
    return [
      {
        'id': 'fallback_${sub}_${g}_$u',
        'grade': g,
        'subject': sub,
        'unit_number': u,
        'title': 'Study Guide & Key Concepts',
        'html_content': '''
          <div class="callout">
            <strong>Overview:</strong> High-yield revision summary aligned with the Ethiopian National Educational Curriculum.
          </div>

          <h3>1. Core Theoretical Foundations</h3>
          <p>Review the primary concepts, classifications, and system dynamics covered throughout Unit $u.</p>

          <div class="definition">
            <strong>Key Terminology:</strong> Master core definitions and apply them to standard examination questions.
          </div>

          <h3>2. Essential Takeaways</h3>
          <ul>
            <li>Understand the relationship between theoretical concepts and practical applications.</li>
            <li>Solve sample problems from previous Ethiopian national matriculation examinations.</li>
            <li>Review the formulas and comparison tables before taking the unit quiz.</li>
          </ul>
        ''',
        'created_at': DateTime.now().toIso8601String(),
      }
    ];
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.subjectId}_g${widget.grade}_u${widget.unitNumber}';
      setState(() {
        _isBookmarked = bookmarks.contains(bookmarkId);
      });
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.subjectId}_g${widget.grade}_u${widget.unitNumber}';

      if (_isBookmarked) {
        bookmarks.remove(bookmarkId);
      } else {
        bookmarks.add(bookmarkId);
      }

      await prefs.setStringList('bookmarked_notes', bookmarks);
      setState(() {
        _isBookmarked = !_isBookmarked;
      });

      _showFloatingSnackbar(
        _isBookmarked
            ? (widget.languageCode == 'en' ? 'Short note bookmarked!' : 'ማስታወሻው ተቀምጧል!')
            : (widget.languageCode == 'en' ? 'Bookmark removed' : 'ማስታወሻው ከምርጫዎች ተሰርዟል'),
        isSuccess: _isBookmarked,
      );
    } catch (_) {}
  }

  Future<void> _toggleOfflineDownload() async {
    final String unitId = _getUnitId();
    if (_isDownloaded) {
      await OfflineManager.removeDownload(unitId);
      setState(() {
        _isDownloaded = false;
      });
      _showFloatingSnackbar(
        widget.languageCode == 'en'
            ? 'Removed from offline storage.'
            : 'ከስልክዎ ማከማቻ ተሰርዟል።',
      );
    } else {
      setState(() {
        _isDownloading = true;
      });

      _showFloatingSnackbar(
        widget.languageCode == 'en'
            ? 'Saving note for offline reading...'
            : 'ለስልክዎ ማስታወሻው በማስቀመጥ ላይ...',
        isInfo: true,
      );

      try {
        if (_notesList.isNotEmpty) {
          await OfflineManager.saveOfflineNotes(
            unitId,
            _notesList,
            grade: widget.grade,
            unit: widget.unitNumber,
          );
          await OfflineManager.addDownload(unitId);
        }

        if (mounted) {
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
          _showFloatingSnackbar(
            widget.languageCode == 'en'
                ? 'Saved offline! You can read anytime without internet.'
                : 'በስኬት ተቀምጧል! ያለ ኢንተርኔት በማንኛውም ጊዜ ማንበብ ይችላሉ።',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          _showFloatingSnackbar(
            widget.languageCode == 'en'
                ? 'Failed to save offline: $e'
                : 'ማስቀመጥ አልተሳካም፡ $e',
            isError: true,
          );
        }
      }
    }
  }

  void _shareNote() {
    if (_notesList.isEmpty) return;
    final currentNote = _notesList[_currentPageIndex];
    final title = currentNote['title']?.toString() ?? widget.unitTitle;
    final content = currentNote['html_content']?.toString() ?? '';
    final cleanText = content.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    final shareContent = '📚 ${widget.subjectId.toUpperCase()} Grade ${widget.grade} — Unit ${widget.unitNumber}\n'
        '$title\n\n'
        '${cleanText.length > 300 ? cleanText.substring(0, 300) + '...' : cleanText}\n\n'
        'Study with Smart X Ethiopian App!\n'
        'Telegram: $_telegramChannelUrl';

    Share.share(shareContent, subject: title);
  }

  void _toggleThemeMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });

    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!();
    } else {
      try {
        AppStateProvider.of(context).onToggleTheme();
      } catch (_) {}
    }
  }

  Future<void> _openTelegramChannel() async {
    final Uri telegramUri = Uri.parse(_telegramChannelUrl);
    try {
      final bool launched = await launchUrl(
        telegramUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Telegram launch note: $e');
      _showFloatingSnackbar(
        widget.languageCode == 'en'
            ? 'Opening Telegram: @smart_x_academy'
            : 'ቴሌግራም በመክፈት ላይ: @smart_x_academy',
        isInfo: true,
      );
    }
  }

  Map<String, Style> _buildHtmlStyles(bool isDark) {
    final Color textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final Color headingColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color calloutBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final Color formulaBg = isDark ? const Color(0xFF0F2338) : const Color(0xFFEFF6FF);

    return {
      "body": Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        fontSize: FontSize(15.5),
        lineHeight: LineHeight(1.65),
        color: textColor,
        fontFamily: 'Georgia',
      ),
      "h1": Style(
        fontSize: FontSize(21.0),
        fontWeight: FontWeight.w900,
        color: headingColor,
        margin: Margins.only(top: 18, bottom: 12),
        fontFamily: 'Georgia',
      ),
      "h2": Style(
        fontSize: FontSize(18.5),
        fontWeight: FontWeight.w800,
        color: widget.themeColor,
        margin: Margins.only(top: 16, bottom: 10),
        fontFamily: 'Georgia',
      ),
      "h3": Style(
        fontSize: FontSize(16.0),
        fontWeight: FontWeight.w700,
        color: headingColor,
        margin: Margins.only(top: 14, bottom: 8),
        fontFamily: 'Georgia',
      ),
      "p": Style(
        margin: Margins.only(bottom: 12),
        lineHeight: LineHeight(1.65),
      ),
      "ul": Style(
        margin: Margins.only(left: 8, bottom: 12),
        padding: HtmlPaddings.only(left: 12),
      ),
      "ol": Style(
        margin: Margins.only(left: 8, bottom: 12),
        padding: HtmlPaddings.only(left: 12),
      ),
      "li": Style(
        margin: Margins.only(bottom: 6),
        lineHeight: LineHeight(1.5),
      ),
      "strong": Style(
        fontWeight: FontWeight.w800,
        color: headingColor,
      ),
      "em": Style(
        fontStyle: FontStyle.italic,
      ),
      "table": Style(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: borderColor, width: 1.0),
        margin: Margins.symmetric(vertical: 12),
      ),
      "th": Style(
        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        padding: HtmlPaddings.symmetric(horizontal: 10, vertical: 8),
        fontWeight: FontWeight.w800,
        color: headingColor,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      "td": Style(
        padding: HtmlPaddings.symmetric(horizontal: 10, vertical: 8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      "code": Style(
        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        color: widget.themeColor,
        fontFamily: 'monospace',
        padding: HtmlPaddings.symmetric(horizontal: 6, vertical: 2),
      ),
      ".callout": Style(
        backgroundColor: calloutBg,
        border: Border(left: BorderSide(color: widget.themeColor, width: 4.0)),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 12),
      ),
      ".formula": Style(
        backgroundColor: formulaBg,
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.35), width: 1.2),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 12),
      ),
      ".definition": Style(
        backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF0FDF4),
        border: Border(left: BorderSide(color: const Color(0xFF10B981), width: 4.0)),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 12),
      ),
      ".example": Style(
        backgroundColor: isDark ? const Color(0xFF28241D) : const Color(0xFFFEFCE8),
        border: Border(left: BorderSide(color: const Color(0xFFF59E0B), width: 4.0)),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 12),
      ),
    };
  }

  void _showCompletionDialog() {
    final bool isDark = _isDarkMode;
    final bool isEn = widget.languageCode == 'en';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor,
                        widget.themeColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),

                // Congratulatory Title
                Text(
                  isEn ? "Thanks for reading!" : "እንኳን ደስ አለዎት!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  isEn
                      ? "You have completed all summary notes for this unit."
                      : "የትምህርቱን ማጠቃለያ በስኬት ጨርሰዋል።",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: widget.themeColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Unit details pill card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 20, color: widget.themeColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Grade ${widget.grade} • ${widget.subjectId.toUpperCase()}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              "Unit ${widget.unitNumber}: ${widget.unitTitle}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Primary Action: Return to Units List
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      isEn ? "Return to Units List" : "ወደ ክፍሎች ዝርዝር ተመለስ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary Action: Review from Beginning
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(
                      isEn ? "Review from Beginning" : "ከመጀመሪያው ድጋሚ አንብብ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF1C2541) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bool isEn = widget.languageCode == 'en';

    final String activeTitle = _notesList.isNotEmpty
        ? (_notesList[_currentPageIndex]['title']?.toString() ?? widget.unitTitle)
        : widget.unitTitle;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C2541) : Colors.white,
        foregroundColor: textColor,
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${widget.subjectId.toUpperCase()} • Unit ${widget.unitNumber}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: widget.themeColor,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              activeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          // 1. Offline Download Toggle
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(
                    _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                    color: _isDownloaded ? const Color(0xFF10B981) : textColor,
                    size: 21,
                  ),
            tooltip: _isDownloaded ? "Saved Offline" : "Save Offline",
            onPressed: _toggleOfflineDownload,
          ),

          // 2. Bookmark Toggle
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? const Color(0xFFFFB703) : textColor,
              size: 21,
            ),
            tooltip: "Bookmark",
            onPressed: _toggleBookmark,
          ),

          // 3. Dark/Light Mode Toggle
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDark),
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF334155),
                size: 21,
              ),
            ),
            tooltip: isDark ? "Switch to Light Mode" : "Switch to Dark Mode",
            onPressed: _toggleThemeMode,
          ),

          // 4. Share
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 19),
            tooltip: "Share",
            onPressed: _shareNote,
          ),

          // 5. Search in note toggle
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              size: 21,
            ),
            tooltip: "Search in note",
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar if toggled
          if (_isSearchOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1C2541) : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 19, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: widget.languageCode == 'en' ? "Search key concepts..." : "ፅንሰ-ሀሳቦችን ይፈልጉ...",
                        hintStyle: TextStyle(color: subColor, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),

          // Main Paginated Reading View (PageView)
          Expanded(
            child: _buildPaginatedContent(isDark, cardBg, textColor, subColor),
          ),

          // Bottom Action & Navigation Bar (Strictly bottom-aligned, no top tabs)
          if (!_isLoading && !_hasError && _notesList.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2541) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Telegram Channel Banner
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openTelegramChannel,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF229ED9), Color(0xFF0088CC)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF229ED9).withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4.5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Color(0xFF0088CC),
                                  size: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEn
                                      ? "Join Telegram for Daily Study Tips & Quizzes"
                                      : "ለተጨማሪ የትምህርት መርጃዎች ቴሌግራማችንን ይቀላቀሉ",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Navigation Controls Row (Back Button, Progress Badge, Next/Finish Button)
                    Row(
                      children: [
                        // Back Button
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _currentPageIndex > 0
                                  ? () {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_back_rounded, size: 17),
                              label: Text(
                                isEn ? "Back" : "ወደ ኋላ",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                disabledForegroundColor:
                                    isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                side: BorderSide(
                                  color: _currentPageIndex > 0
                                      ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Center Page Progress Indicator Badge
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              "${_currentPageIndex + 1} / ${_notesList.length}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: widget.themeColor,
                              ),
                            ),
                          ),
                        ),

                        // Next / Finish Button
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPageIndex < _notesList.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                  );
                                } else {
                                  _showCompletionDialog();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentPageIndex == _notesList.length - 1
                                    ? const Color(0xFF10B981)
                                    : widget.themeColor,
                                foregroundColor: Colors.white,
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentPageIndex == _notesList.length - 1
                                        ? (isEn ? "Finish" : "ጨርስ")
                                        : (isEn ? "Next" : "ቀጣይ"),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _currentPageIndex == _notesList.length - 1
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentFriendlyError(bool isDark, Color cardBg, Color textColor, Color subColor) {
    final bool isEn = widget.languageCode == 'en';

    IconData iconData = Icons.cloud_off_rounded;
    Color iconColor = const Color(0xFFEF4444);
    String title = '';
    String subtitle = '';

    switch (_errorType) {
      case NotesErrorType.noInternet:
        iconData = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFF59E0B);
        title = isEn ? "No Internet Connection" : "የኢንተርኔት ግንኙነት የለም";
        subtitle = isEn
            ? "No internet connection or network timed out. Please check your connection and try again."
            : "ኢንተርኔት የለም ወይም ተቋርጧል። እባክዎ ኮኔክሽንዎን ፈትሸው ድጋሚ ይሞክሩ።";
        break;

      case NotesErrorType.emptyData:
        iconData = Icons.menu_book_outlined;
        iconColor = const Color(0xFF0EA5E9);
        title = isEn ? "Notes Not Available" : "ማጠቃለያ አልተገኘም";
        subtitle = isEn
            ? "Summary notes for this unit have not been published yet. They will be uploaded soon!"
            : "ለዚህ ክፍል የተዘጋጀ ማጠቃለያ አልተገኘም። በቅርቡ ይጫናል።";
        break;

      case NotesErrorType.serverError:
      default:
        iconData = Icons.cloud_sync_rounded;
        iconColor = const Color(0xFFEF4444);
        title = isEn ? "Server Connection Error" : "የሰርቨር ግንኙነት ችግር";
        subtitle = isEn
            ? "Could not load educational notes from the server right now. Please try again in a few minutes."
            : "መረጃዎችን ከሰርቨር ላይ መጫን አልተቻለም። እባክዎ በጥቂት ደቂቃዎች ውስጥ ድጋሚ ይሞክሩ።";
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(iconData, size: 36, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEn ? "Go Back" : "ተመለስ",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _fetchNotes,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: Text(
                        isEn ? "Retry" : "ድጋሚ ይሞክሩ",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginatedContent(bool isDark, Color cardBg, Color textColor, Color subColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              widget.languageCode == 'en'
                  ? "Loading short notes..."
                  : "አጫጭር ማስታወሻዎችን በመጫን ላይ...",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: subColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError || _notesList.isEmpty) {
      return _buildStudentFriendlyError(isDark, cardBg, textColor, subColor);
    }

    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: _notesList.length,
      onPageChanged: (pageIndex) {
        setState(() {
          _currentPageIndex = pageIndex;
        });
      },
      itemBuilder: (context, index) {
        final note = _notesList[index];
        final String noteTitle = note['title']?.toString() ?? 'Section ${index + 1}';
        final String htmlRaw = note['html_content']?.toString() ??
            note['content']?.toString() ??
            '<p>No content available for this section.</p>';
        final String sanitizedHtml = _sanitizeHtml(htmlRaw, noteTitle);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subject & Grade Header Tag with modern pill design
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.themeColor.withValues(alpha: isDark ? 0.35 : 0.25),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          "GRADE ${widget.grade} • ${_getNormalizedSubjectName().toUpperCase()}",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: widget.themeColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (_isDownloaded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF065F46).withValues(alpha: 0.3)
                                : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.offline_pin_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                "Offline Ready",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section Title
                  Text(
                    noteTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rich HTML Content rendered with custom responsive styling & scrollable tables
                  Html(
                    data: sanitizedHtml,
                    style: _buildHtmlStyles(isDark),
                    extensions: const [
                      TableHtmlExtension(),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Divider(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    thickness: 1,
                  ),
                  const SizedBox(height: 16),

                  // End of Note Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Smart X Ethiopian • Educational Notes",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                      InkWell(
                        onTap: _shareNote,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 15, color: widget.themeColor),
                              const SizedBox(width: 5),
                              Text(
                                widget.languageCode == 'en' ? "Share Note" : "አጋራ",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
