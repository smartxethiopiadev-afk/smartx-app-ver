import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worksheet_model.dart';
import '../models/package_model.dart';
import 'offline_manager.dart';

class WorksheetService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Normalizes subject names for querying
  static String _normalizeSubject(String rawSubject) {
    final s = rawSubject.toLowerCase().trim();
    if (s.contains('math')) return 'Mathematics';
    if (s.contains('phys')) return 'Physics';
    if (s.contains('chem')) return 'Chemistry';
    if (s.contains('bio')) return 'Biology';
    if (s.contains('eng')) return 'English';
    if (s.contains('econ')) return 'Economics';
    if (s.contains('geog') || s.contains('geo')) return 'Geography';
    if (s.contains('hist')) return 'History';
    if (s.contains('agri') || s.contains('agr')) return 'Agriculture';
    if (s.contains('it') || s.contains('info') || s.contains('comp')) {
      return 'Information Technology';
    }
    return rawSubject;
  }

  /// Fetches worksheets for a specific grade, subject, and unit.
  /// Falls back to offline cache or built-in curriculum worksheets.
  static Future<List<WorksheetModel>> fetchWorksheets({
    required int grade,
    required String subject,
    required int unit,
  }) async {
    final String unitKey = '${grade}_${subject.toLowerCase()}_u$unit';
    final bool hasConn = await OfflineManager.isNetworkAvailable();

    // 1. If offline, return immediately from offline storage
    if (!hasConn) {
      final cached = await OfflineManager.getOfflineWorksheets(unitKey);
      if (cached.isNotEmpty) {
        return cached;
      }
      return _generateCurriculumFallbackWorksheets(grade, subject, unit);
    }

    // 2. Query Supabase
    try {
      final normSubject = _normalizeSubject(subject);
      final response = await _supabase
          .from('worksheets')
          .select('*')
          .eq('grade', grade)
          .eq('unit_number', unit)
          .ilike('subject', '%$normSubject%');

      if (response.isNotEmpty) {
        final worksheets = (response as List<dynamic>)
            .map((item) =>
                WorksheetModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache for offline access
        await OfflineManager.saveOfflineWorksheets(
          unitKey,
          worksheets,
          grade: grade,
          unit: unit,
        );

        return worksheets;
      }
    } catch (e) {
      debugPrint('[WorksheetService] Supabase fetch error: $e');
    }

    // 3. Fallback to offline cache if available
    final cached = await OfflineManager.getOfflineWorksheets(unitKey);
    if (cached.isNotEmpty) {
      return cached;
    }

    // 4. Fallback to built-in curriculum seed worksheets
    final fallbackList =
        _generateCurriculumFallbackWorksheets(grade, subject, unit);
    await OfflineManager.saveOfflineWorksheets(
      unitKey,
      fallbackList,
      grade: grade,
      unit: unit,
    );
    return fallbackList;
  }

  /// Fetches curriculum packages from Supabase with fallback to local defaults
  static Future<List<PackageModel>> fetchPackages({int? grade}) async {
    try {
      final bool hasConn = await OfflineManager.isNetworkAvailable();
      if (hasConn) {
        var query = _supabase.from('packages').select('*');
        if (grade != null) {
          query = query.eq('grade', grade);
        }
        final response = await query.order('grade', ascending: true);
        if (response.isNotEmpty) {
          return (response as List<dynamic>)
              .map((e) => PackageModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[WorksheetService] Error fetching packages from Supabase: $e');
    }

    // Return default packages
    if (grade != null) {
      return PackageModel.defaultPackages
          .where((p) => p.grade == grade)
          .toList();
    }
    return PackageModel.defaultPackages;
  }

  /// Generates rich, authentic Ethiopian curriculum practice problems for units
  static List<WorksheetModel> _generateCurriculumFallbackWorksheets(
    int grade,
    String subject,
    int unit,
  ) {
    final norm = _normalizeSubject(subject);

    if (norm == 'Mathematics') {
      if (unit == 1) {
        return [
          WorksheetModel(
            id: 'ws_g${grade}_math_u1',
            grade: grade,
            subject: 'Mathematics',
            unitNumber: 1,
            title: grade == 9
                ? 'Unit 1: Further on Sets - Practice Worksheet'
                : (grade == 10
                    ? 'Unit 1: Relations and Functions - Practice Worksheet'
                    : (grade == 11
                        ? 'Unit 1: Further on Logic - Practice Worksheet'
                        : 'Unit 1: Sequences and Series - EUEE Model Worksheet')),
            questionsHtml: r'''
<div class="question" data-number="1">
  <h3>Question 1</h3>
  <p>Let $A = \{1, 2, 3, 4, 5\}$ and $B = \{3, 4, 5, 6, 7\}$.</p>
  <p>Find the symmetric difference $A \Delta B$ and the total number of subsets of $A \cap B$.</p>
</div>
<div class="question" data-number="2">
  <h3>Question 2</h3>
  <p>In a survey of 60 Ethiopian high school students, 35 study Physics, 30 study Chemistry, and 8 study neither subject.</p>
  <p>Calculate the number of students who study <strong>both</strong> subjects, and illustrate with a Venn diagram description.</p>
</div>
<div class="question" data-number="3">
  <h3>Question 3</h3>
  <p>Simplify the algebraic expression using set laws: $(A \cup B) \cap (A \cup B')$.</p>
</div>
''',
            solutionsHtml: r'''
<div class="solution" data-number="1">
  <h4>Solution for Question 1:</h4>
  <p><strong>Step 1:</strong> Symmetric difference $A \Delta B = (A \setminus B) \cup (B \setminus A)$.</p>
  <p>$A \setminus B = \{1, 2\}$</p>
  <p>$B \setminus A = \{6, 7\}$</p>
  <p>Therefore, $A \Delta B = \{1, 2, 6, 7\}$.</p>
  <p><strong>Step 2:</strong> Intersection $A \cap B = \{3, 4, 5\}$. Number of elements $n(A \cap B) = 3$.</p>
  <p>Total subsets $= 2^n = 2^3 = 8$ subsets.</p>
</div>
<div class="solution" data-number="2">
  <h4>Solution for Question 2:</h4>
  <p><strong>Step 1:</strong> Total surveyed students $n(U) = 60$.</p>
  <p>Students taking at least one subject: $n(P \cup C) = 60 - 8 = 52$.</p>
  <p><strong>Step 2:</strong> Inclusion-Exclusion Formula:</p>
  <p>$$n(P \cup C) = n(P) + n(C) - n(P \cap C)$$</p>
  <p>$$52 = 35 + 30 - n(P \cap C) = 65 - n(P \cap C)$$</p>
  <p>$$n(P \cap C) = 65 - 52 = 13$$</p>
  <p><strong>Final Answer:</strong> Exactly 13 students study both Physics and Chemistry.</p>
</div>
<div class="solution" data-number="3">
  <h4>Solution for Question 3:</h4>
  <p>Apply the Distributive Law of set theory in reverse:</p>
  <p>$$(A \cup B) \cap (A \cup B') = A \cup (B \cap B')$$</p>
  <p>Since $B \cap B' = \emptyset$ (complement law):</p>
  <p>$$A \cup \emptyset = A$$</p>
  <p><strong>Final Answer:</strong> $A$.</p>
</div>
''',
            packageId: 'pkg_grade_$grade',
          ),
        ];
      } else {
        // Unit 2+
        return [
          WorksheetModel(
            id: 'ws_g${grade}_math_u$unit',
            grade: grade,
            subject: 'Mathematics',
            unitNumber: unit,
            title: 'Unit $unit: Curriculum Mastery Worksheet (Grade $grade)',
            questionsHtml: r'''
<div class="question" data-number="1">
  <h3>Question 1</h3>
  <p>Solve the quadratic equation using the quadratic formula: $2x^2 - 7x + 3 = 0$.</p>
</div>
<div class="question" data-number="2">
  <h3>Question 2</h3>
  <p>If $\sin(\theta) = \frac{3}{5}$ and $\theta$ is an acute angle, find the exact values of $\cos(\theta)$ and $\tan(\theta)$.</p>
</div>
<div class="question" data-number="3">
  <h3>Question 3</h3>
  <p>Rationalize the denominator and simplify: $\frac{6}{\sqrt{7} - 1}$.</p>
</div>
''',
            solutionsHtml: r'''
<div class="solution" data-number="1">
  <h4>Solution for Question 1:</h4>
  <p>Quadratic formula: $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$</p>
  <p>Here $a = 2$, $b = -7$, $c = 3$.</p>
  <p>Discriminant: $D = (-7)^2 - 4(2)(3) = 49 - 24 = 25$.</p>
  <p>$$x = \frac{7 \pm \sqrt{25}}{4} = \frac{7 \pm 5}{4}$$</p>
  <p>$x_1 = \frac{12}{4} = 3$, $x_2 = \frac{2}{4} = \frac{1}{2}$.</p>
  <p><strong>Roots:</strong> $x = 3$ or $x = \frac{1}{2}$.</p>
</div>
<div class="solution" data-number="2">
  <h4>Solution for Question 2:</h4>
  <p>Using Pythagorean identity: $\sin^2(\theta) + \cos^2(\theta) = 1$.</p>
  <p>$$\cos(\theta) = \sqrt{1 - \left(\frac{3}{5}\right)^2} = \sqrt{1 - \frac{9}{25}} = \sqrt{\frac{16}{25}} = \frac{4}{5}$$</p>
  <p>$$\tan(\theta) = \frac{\sin(\theta)}{\cos(\theta)} = \frac{3/5}{4/5} = \frac{3}{4}$$</p>
</div>
<div class="solution" data-number="3">
  <h4>Solution for Question 3:</h4>
  <p>Multiply numerator and denominator by conjugate $(\sqrt{7} + 1)$:</p>
  <p>$$\frac{6(\sqrt{7} + 1)}{(\sqrt{7} - 1)(\sqrt{7} + 1)} = \frac{6(\sqrt{7} + 1)}{7 - 1} = \frac{6(\sqrt{7} + 1)}{6} = \sqrt{7} + 1$$</p>
</div>
''',
            packageId: 'pkg_grade_$grade',
          ),
        ];
      }
    }

    // Default science/other subjects worksheet
    return [
      WorksheetModel(
        id: 'ws_g${grade}_${norm.toLowerCase()}_u$unit',
        grade: grade,
        subject: norm,
        unitNumber: unit,
        title: '$norm - Unit $unit Practice Worksheet',
        questionsHtml: '''
<div class="question" data-number="1">
  <h3>Question 1</h3>
  <p>Explain the fundamental principles governing Unit $unit in $norm, and define the key SI units associated with each quantity.</p>
</div>
<div class="question" data-number="2">
  <h3>Question 2</h3>
  <p>A sample problem requires calculating the rate of change given \$v_1 = 10\\text{ m/s}\$ and \$v_2 = 30\\text{ m/s}\$ over \$\\Delta t = 4\\text{ s}\$. Determine the average acceleration \$a_{\\text{avg}}\$.</p>
</div>
<div class="question" data-number="3">
  <h3>Question 3</h3>
  <p>Discuss the practical applications of this chapter in Ethiopian technological and industrial development.</p>
</div>
''',
        solutionsHtml: r'''
<div class="solution" data-number="1">
  <h4>Solution for Question 1:</h4>
  <p>The fundamental concepts establish conservation laws and systematic measurement. The base SI units are meters (m), seconds (s), and kilograms (kg).</p>
</div>
<div class="solution" data-number="2">
  <h4>Solution for Question 2:</h4>
  <p>$$a_{\text{avg}} = \frac{\Delta v}{\Delta t} = \frac{v_2 - v_1}{\Delta t} = \frac{30 - 10}{4} = \frac{20}{4} = 5\text{ m/s}^2$$</p>
  <p><strong>Answer:</strong> Acceleration is $5\text{ m/s}^2$.</p>
</div>
<div class="solution" data-number="3">
  <h4>Solution for Question 3:</h4>
  <p>Applications include civil infrastructure (GERD, railways), renewable energy production, agricultural mechanization, and environmental management.</p>
</div>
''',
        packageId: 'pkg_grade_$grade',
      ),
    ];
  }
}
