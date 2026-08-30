import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/subject_model.dart';
import '../models/note_model.dart';
import '../models/note_chunk_helper.dart';
import '../services/offline_service.dart';
import '../services/google_analytics_service.dart';
import '../widgets/user_error_view.dart';

class NotesScreen extends StatefulWidget {
  final UnitModel unit;
  final SubjectConfig subject;
  final int grade;

  const NotesScreen({
    super.key,
    required this.unit,
    required this.subject,
    required this.grade,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _wordsPerChunk = 150;
  int _currentChunkIndex = 0;
  double _fontSize = 14.5;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentChunkIndex);

    // Dispatch Google Analytics Screen & Read Event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offline = Provider.of<OfflineService>(context, listen: false);
      GoogleAnalyticsService.logEvent(
        eventName: 'screen_view',
        deviceId: offline.deviceId,
        parameters: {
          'screen_name': 'NotesScreen',
          'subject': widget.subject.id,
          'grade': widget.grade,
          'unit_number': widget.unit.unitNumber,
        },
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;
    final ShortNoteModel note = offline.getShortNoteForUnit(
      widget.unit.unitId,
      widget.subject.enTitle,
      widget.grade,
      widget.unit.unitNumber,
    );
    final isDownloaded = offline.isUnitDownloaded(widget.unit.unitId);

    // Split content by word count chunks
    final List<NoteChunk> chunks = NoteChunkHelper.splitIntoWordChunks(
      note.content,
      targetWordsPerChunk: _wordsPerChunk,
    );

    if (chunks.isEmpty || note.content.trim().isEmpty) {
      return Scaffold(
        backgroundColor: AppConfig.darkBackground,
        appBar: AppBar(
          backgroundColor: AppConfig.darkCard,
          title: Text(isAm ? 'ማስታወሻ አልተገኘም' : 'Notes Unavailable'),
        ),
        body: UserErrorView(
          type: ErrorDisplayType.emptyContent,
          customTitle: isAm ? 'ይህ ዩኒት በማዘጋጀት ላይ ነው' : 'Notes Under Review',
          amharicMessage: isAm
              ? 'የዚህ ዩኒት ማጠቃለያ በቅርቡ ይጫናል። ጥያቄዎችን ለመለማመድ Quiz መክፈት ይችላሉ።'
              : 'Short notes for this unit will be added soon. You can practice unit quizzes in the meantime.',
          contextTag: '${widget.subject.code}_G${widget.grade}_U${widget.unit.unitNumber}',
          onRetry: () => setState(() {}),
        ),
      );
    }

    // Guard safe chunk index
    if (_currentChunkIndex >= chunks.length) {
      _currentChunkIndex = 0;
    }
    final activeChunk = chunks[_currentChunkIndex];

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.subject.code} • Unit ${widget.unit.unitNumber}',
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              isAm
                  ? 'በቃላት ብዛት የተከፋፈለ (Words-Based Chunks)'
                  : 'Bite-Sized Reading (~$_wordsPerChunk words/page)',
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          // Text Size Adjuster
          IconButton(
            icon: const Icon(Icons.format_size_rounded, color: Colors.white70, size: 20),
            tooltip: isAm ? 'የጽሑፍ መጠን' : 'Adjust Text Size',
            onPressed: () {
              setState(() {
                if (_fontSize >= 18.0) {
                  _fontSize = 13.0;
                } else {
                  _fontSize += 1.5;
                }
              });
            },
          ),
          // Download / Offline Toggle
          IconButton(
            icon: Icon(
              isDownloaded ? Icons.offline_pin : Icons.download_outlined,
              color: isDownloaded ? AppConfig.primaryGreen : Colors.white70,
            ),
            tooltip: isDownloaded ? 'Available Offline' : 'Download for Offline Study',
            onPressed: () {
              offline.toggleUnitDownload(widget.unit, widget.subject.id, widget.grade);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isDownloaded
                        ? (isAm ? 'ዩኒቱ ከመሳሪያዎ ተሰርዟል' : 'Unit removed from offline storage')
                        : (isAm ? 'ማጠቃለያውና ጥያቄዎቹ በተሳካ ሁኔታ ወርደዋል!' : 'Notes & questions downloaded for offline access!'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          // Share Active Word Chunk to Telegram
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF29B6F6), size: 20),
            tooltip: isAm ? 'ይህን ክፍል በቴሌግራም አጋራ' : 'Share Active Chunk to Telegram',
            onPressed: () {
              final shareText = '''
[Smart X Ethiopia • ${widget.subject.code} G${widget.grade} U${widget.unit.unitNumber}]
Chunk ${_currentChunkIndex + 1} of ${chunks.length} (${activeChunk.wordCount} words):

${activeChunk.text}

Join Channel: @smartx_ethiopia
''';
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAm
                        ? 'የተመረጠው ክፍል ተገልብጧል! በቴሌግራም (@smartx_ethiopia) መጋራት ይችላሉ።'
                        : 'Active word chunk copied! Share at @smartx_ethiopia',
                  ),
                  backgroundColor: const Color(0xFF0288D1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Word Density Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppConfig.darkCard,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chunk progress indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.subject.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${isAm ? "ክፍል" : "Part"} ${_currentChunkIndex + 1}/${chunks.length}',
                              style: TextStyle(
                                color: widget.subject.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activeChunk.wordCount} ${isAm ? "ቃላት" : "words"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ~${activeChunk.estimatedSeconds}s read',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),

                      // Words per Chunk Density Selector (100, 150, 200 words)
                      PopupMenuButton<int>(
                        initialValue: _wordsPerChunk,
                        tooltip: isAm ? 'የቃላት ብዛት ምረጥ' : 'Words per page density',
                        onSelected: (val) {
                          setState(() {
                            _wordsPerChunk = val;
                            _currentChunkIndex = 0;
                          });
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 100, child: Text('100 words/page (አጫጭር)')),
                          const PopupMenuItem(value: 150, child: Text('150 words/page (መካከለኛ - Default)')),
                          const PopupMenuItem(value: 220, child: Text('220 words/page (ሰፋ ያለ)')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tune_rounded, size: 14, color: AppConfig.accentAmber),
                              const SizedBox(width: 4),
                              Text(
                                '$_wordsPerChunk w/p',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar for whole note
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentChunkIndex + 1) / chunks.length,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.subject.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Word Chunk Selector Pills
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: chunks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final isSelected = idx == _currentChunkIndex;
                  final chunk = chunks[idx];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentChunkIndex = idx);
                      _pageController.jumpToPage(idx);
                      _logChunkAnalytics(chunk, idx, chunks.length);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.subject.primaryColor : AppConfig.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? widget.subject.primaryColor : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '#${idx + 1} (${chunk.wordCount}w)',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Word Chunk Page View Body
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: chunks.length,
                onPageChanged: (idx) {
                  setState(() => _currentChunkIndex = idx);
                  _logChunkAnalytics(chunks[idx], idx, chunks.length);
                },
                itemBuilder: (context, index) {
                  final chunk = chunks[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppConfig.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.notes_rounded, color: widget.subject.primaryColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    chunk.title,
                                    style: TextStyle(
                                      color: widget.subject.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${chunk.wordCount} words',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 14),
                          SelectableText(
                            chunk.text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _fontSize,
                              height: 1.65,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls Bar (Previous / Next Word Chunks)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppConfig.darkCard,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _currentChunkIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(isAm ? 'ያለፈው ክፍል' : 'Previous Part'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.subject.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_currentChunkIndex < chunks.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isAm ? 'ሁሉንም ክፍሎች አንብበው ጨርሰዋል! ጎበዝ!' : 'You have completed all word chunks! Great job!'),
                              backgroundColor: AppConfig.primaryGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        _currentChunkIndex < chunks.length - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_outline,
                        size: 16,
                      ),
                      label: Text(
                        _currentChunkIndex < chunks.length - 1
                            ? (isAm ? 'ቀጣይ ክፍል' : 'Next Part')
                            : (isAm ? 'ተጠናቋል' : 'Finish'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logChunkAnalytics(NoteChunk chunk, int index, int total) {
    final offline = Provider.of<OfflineService>(context, listen: false);
    GoogleAnalyticsService.logNoteWordChunkRead(
      unitId: widget.unit.unitId,
      subject: widget.subject.id,
      grade: widget.grade,
      chunkNumber: index + 1,
      totalChunks: total,
      wordsCount: chunk.wordCount,
      deviceId: offline.deviceId,
    );
  }
}
