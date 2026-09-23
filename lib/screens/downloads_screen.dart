import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../models/offline_package_model.dart';
import '../services/offline_manager.dart';
import '../services/download_service.dart';
import '../services/quiz_service.dart';
import 'pdf_viewer_screen.dart';
import 'quiz_screen.dart';

class DownloadsHubScreen extends StatefulWidget {
  final int? initialGrade;
  final String? initialSubject;
  final int initialTabIndex; // 0 for PDFs, 1 for Questions

  const DownloadsHubScreen({
    super.key,
    this.initialGrade,
    this.initialSubject,
    this.initialTabIndex = 0,
  });

  @override
  State<DownloadsHubScreen> createState() => _DownloadsHubScreenState();
}

// Keep backward compatibility alias
typedef DownloadsScreen = DownloadsHubScreen;

class _DownloadsHubScreenState extends State<DownloadsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<OfflinePdfModel> _allPdfs = [];
  List<OfflinePdfModel> _filteredPdfs = [];

  List<OfflineQuestionPackage> _allQuestionPkgs = [];
  List<OfflineQuestionPackage> _filteredQuestionPkgs = [];

  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedGradeFilter;

  int _totalPdfBytes = 0;
  int _totalQuestionBytes = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _selectedGradeFilter = widget.initialGrade;
    _loadAllDownloads();
    OfflineManager.addListener(_onOfflineChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    OfflineManager.removeListener(_onOfflineChanged);
    super.dispose();
  }

  void _onOfflineChanged() {
    if (mounted) {
      _loadAllDownloads();
    }
  }

  Future<void> _loadAllDownloads() async {
    setState(() => _isLoading = true);

    final pdfs = await OfflineManager.getAllOfflinePdfs();
    final pkgs = await OfflineManager.getAllQuestionPackages();
    final storage = await OfflineManager.getStorageUsageBytes();

    if (mounted) {
      setState(() {
        _allPdfs = pdfs;
        _allQuestionPkgs = pkgs;
        _totalPdfBytes = storage['pdfBytes'] ?? 0;
        _totalQuestionBytes = storage['questionBytes'] ?? 0;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase().trim();

    // 1. Filter PDFs
    List<OfflinePdfModel> pdfResults = List.from(_allPdfs);
    if (_selectedGradeFilter != null) {
      pdfResults = pdfResults.where((item) => item.grade == _selectedGradeFilter).toList();
    }
    if (query.isNotEmpty) {
      pdfResults = pdfResults.where((item) {
        final tMatch = item.title.toLowerCase().contains(query);
        final sMatch = item.subject.toLowerCase().contains(query);
        final uMatch = 'unit ${item.unit}'.contains(query);
        return tMatch || sMatch || uMatch;
      }).toList();
    }

    // 2. Filter Question Packages
    List<OfflineQuestionPackage> pkgResults = List.from(_allQuestionPkgs);
    if (_selectedGradeFilter != null) {
      pkgResults = pkgResults.where((item) => item.grade == _selectedGradeFilter).toList();
    }
    if (query.isNotEmpty) {
      pkgResults = pkgResults.where((item) {
        final tMatch = item.title.toLowerCase().contains(query);
        final sMatch = item.subject.toLowerCase().contains(query);
        final uMatch = 'unit ${item.unit}'.contains(query);
        return tMatch || sMatch || uMatch;
      }).toList();
    }

    setState(() {
      _filteredPdfs = pdfResults;
      _filteredQuestionPkgs = pkgResults;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFF2563EB);
    if (s.contains('bio')) return const Color(0xFF10B981);
    if (s.contains('phys')) return const Color(0xFFEF4444);
    if (s.contains('chem')) return const Color(0xFF8B5CF6);
    if (s.contains('civ')) return const Color(0xFF64748B);
    if (s.contains('geog') || s.contains('geo')) return const Color(0xFF0D9488);
    if (s.contains('hist')) return const Color(0xFFD97706);
    if (s.contains('agri')) return const Color(0xFF16A34A);
    if (s.contains('econ')) return const Color(0xFF0284C7);
    return const Color(0xFF2563EB);
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Icons.functions_rounded;
    if (s.contains('bio')) return Icons.biotech_rounded;
    if (s.contains('phys')) return Icons.bolt_rounded;
    if (s.contains('chem')) return Icons.science_rounded;
    if (s.contains('civ')) return Icons.gavel_rounded;
    if (s.contains('geog') || s.contains('geo')) return Icons.public_rounded;
    if (s.contains('hist')) return Icons.account_balance_rounded;
    if (s.contains('agri')) return Icons.agriculture_rounded;
    if (s.contains('econ')) return Icons.trending_up_rounded;
    return Icons.menu_book_rounded;
  }

  void _openPdf(OfflinePdfModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: item.pdfUrl,
          title: item.title,
          subject: item.subject,
          grade: item.grade,
          unitNumber: item.unit,
          localFilePath: item.localPath.isNotEmpty ? item.localPath : null,
        ),
      ),
    );
  }

  void _startOfflineQuiz(OfflineQuestionPackage pkg, {required QuizMode mode}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          grade: pkg.grade,
          subject: pkg.subject,
          unit: pkg.unit,
          isOffline: true,
          offlineUnitId: pkg.unitId,
          mode: mode,
        ),
      ),
    );
  }

  Future<void> _confirmDeletePdf(OfflinePdfModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Downloaded Note?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Do you want to delete "${item.title}" (${_formatBytes(item.fileSize)}) from your local storage? You can re-download it anytime with an internet connection.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OfflineManager.deleteOfflinePdf(item.unitId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteQuestionPackage(OfflineQuestionPackage pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Question Package?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Do you want to delete "${pkg.title}" (${pkg.totalQuestions} questions) from your offline database? You will need an internet connection to practice this unit again.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OfflineManager.deleteQuestionPackage(pkg.unitId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pkg.title} deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 10),
            Text(
              'Clear All Downloads?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'This will permanently remove all ${_allPdfs.length} PDF Notes and ${_allQuestionPkgs.length} Question Packages (${_formatBytes(_totalPdfBytes + _totalQuestionBytes)}) from your device storage.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep Files',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OfflineManager.deleteAllDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All downloaded files cleared successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = AppStateProvider.of(context);
    final isDark = appConfig.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Downloads & Offline Hub',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          if (_allPdfs.isNotEmpty || _allQuestionPkgs.isNotEmpty)
            IconButton(
              tooltip: 'Clear All Downloads',
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
              onPressed: _confirmClearAllDownloads,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: _loadAllDownloads,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: subColor,
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              text: 'PDF Notes (${_allPdfs.length})',
            ),
            Tab(
              icon: const Icon(Icons.quiz_rounded, size: 20),
              text: 'Question Sets (${_allQuestionPkgs.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active Background Downloads Indicator
          ValueListenableBuilder<Map<String, DownloadTaskState>>(
            valueListenable: DownloadService.tasksNotifier,
            builder: (context, tasks, _) {
              if (tasks.isEmpty) return const SizedBox.shrink();
              return Column(
                children: tasks.values.map((task) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Downloading: ${task.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            Text(
                              '${(task.progress * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task.progress,
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Total Storage Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.offline_pin_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Study Storage',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_allPdfs.length} PDFs (${_formatBytes(_totalPdfBytes)}) • ${_allQuestionPkgs.length} Question Sets (${_formatBytes(_totalQuestionBytes)})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val;
                _applyFilters();
              },
              style: GoogleFonts.plusJakartaSans(color: textColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search saved notes, subjects, or units...',
                hintStyle: GoogleFonts.plusJakartaSans(color: subColor, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: subColor, size: 20),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Grade Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All Grades', null, cardBg, textColor, subColor),
                const SizedBox(width: 8),
                _buildFilterChip('Grade 9', 9, cardBg, textColor, subColor),
                const SizedBox(width: 8),
                _buildFilterChip('Grade 10', 10, cardBg, textColor, subColor),
                const SizedBox(width: 8),
                _buildFilterChip('Grade 11', 11, cardBg, textColor, subColor),
                const SizedBox(width: 8),
                _buildFilterChip('Grade 12', 12, cardBg, textColor, subColor),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: PDF Notes List
                      _filteredPdfs.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.picture_as_pdf_outlined,
                              title: _allPdfs.isEmpty ? 'No Downloaded PDF Notes' : 'No Matching Notes Found',
                              description: _allPdfs.isEmpty
                                  ? 'Download curriculum short notes from any unit to read offline without an internet connection.'
                                  : 'Try adjusting your search query or grade filter.',
                              textColor: textColor,
                              subColor: subColor,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredPdfs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _filteredPdfs[index];
                                return _buildPdfCard(item, cardBg, textColor, subColor, borderColor);
                              },
                            ),

                      // Tab 2: Question Packages List
                      _filteredQuestionPkgs.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.quiz_outlined,
                              title: _allQuestionPkgs.isEmpty ? 'No Downloaded Question Sets' : 'No Matching Question Sets',
                              description: _allQuestionPkgs.isEmpty
                                  ? 'Download unit question sets to take Practice and Exam quizzes 100% offline.'
                                  : 'Try adjusting your search query or grade filter.',
                              textColor: textColor,
                              subColor: subColor,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredQuestionPkgs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final pkg = _filteredQuestionPkgs[index];
                                return _buildQuestionPackageCard(pkg, cardBg, textColor, subColor, borderColor);
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int? gradeVal,
    Color cardBg,
    Color textColor,
    Color subColor,
  ) {
    final isSelected = _selectedGradeFilter == gradeVal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGradeFilter = gradeVal;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color subColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 52,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: subColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Browse Curriculum Units',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(
    OfflinePdfModel item,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openPdf(item),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // PDF Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Grade ${item.grade} • Unit ${item.unit}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.fileSize > 0)
                            Text(
                              _formatBytes(item.fileSize),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: subColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subject,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions: Read & Delete
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Read Offline',
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                      onPressed: () => _openPdf(item),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      onPressed: () => _confirmDeletePdf(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPackageCard(
    OfflineQuestionPackage pkg,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final themeColor = _getSubjectColor(pkg.subject);
    final subjectIcon = _getSubjectIcon(pkg.subject);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Subject Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      subjectIcon,
                      color: themeColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Header Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Grade ${pkg.grade} • Unit ${pkg.unit}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pkg.subject,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                            onPressed: () => _confirmDeleteQuestionPackage(pkg),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pkg.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Question Breakdown Badges
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${pkg.totalQuestions} Questions: ${pkg.breakdownText}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: themeColor,
                      ),
                    ),
                  ),
                  Text(
                    pkg.formattedSize,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons (Practice Mode & Exam Mode)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startOfflineQuiz(pkg, mode: QuizMode.practice),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                    label: Text(
                      'Practice Mode',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _startOfflineQuiz(pkg, mode: QuizMode.exam),
                    icon: const Icon(Icons.timer_rounded, size: 16, color: Color(0xFFEF4444)),
                    label: Text(
                      'Exam Mode',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
