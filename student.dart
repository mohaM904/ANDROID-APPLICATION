// ─────────────────────────────────────────────────────────────────────────────
// CHAPTER 1 + 2 — OOP Models: Student, Grade, GradeBook
// Demonstrates: classes, encapsulation, constructors, getters,
//               lambda functions, higher-order functions, sorting, filtering
// ─────────────────────────────────────────────────────────────────────────────

enum GradeCategory { quiz, midterm, final_, assignment, lab }

extension GradeCategoryLabel on GradeCategory {
  String get label => switch (this) {
        GradeCategory.quiz => 'Quiz',
        GradeCategory.midterm => 'Midterm',
        GradeCategory.final_ => 'Final',
        GradeCategory.assignment => 'Assignment',
        GradeCategory.lab => 'Lab',
      };

  double get weight => switch (this) {
        GradeCategory.quiz => 0.10,
        GradeCategory.midterm => 0.25,
        GradeCategory.final_ => 0.35,
        GradeCategory.assignment => 0.20,
        GradeCategory.lab => 0.10,
      };
}

// ── Grade entity ──────────────────────────────────────────────────────────────
class Grade {
  final String title;
  final double score;      // 0–100
  final double maxScore;
  final GradeCategory category;

  const Grade({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.category,
  });

  // Lambda-style getter: percentage as a pure expression
  double get percentage => (score / maxScore) * 100;

  String get letterGrade => _letterFromPercent(percentage);

  static String _letterFromPercent(double p) => switch (p) {
        >= 90 => 'A',
        >= 80 => 'B',
        >= 70 => 'C',
        >= 60 => 'D',
        _ => 'F',
      };

  @override
  String toString() => '$title: ${percentage.toStringAsFixed(1)}% ($letterGrade)';
}

// ── Student entity ────────────────────────────────────────────────────────────
class Student {
  final String id;
  final String name;
  final String major;
  final List<Grade> _grades = [];

  Student({required this.id, required this.name, required this.major});

  // Read-only view of grades (encapsulation)
  List<Grade> get grades => List.unmodifiable(_grades);

  void addGrade(Grade g) => _grades.add(g);
  void removeGradeAt(int index) => _grades.removeAt(index);

  // ── Higher-Order Function: weighted average using fold ─────────────────────
  double get weightedAverage {
    if (_grades.isEmpty) return 0;

    // Group by category → lambda map
    final Map<GradeCategory, List<Grade>> grouped = {};
    for (final g in _grades) {
      grouped.putIfAbsent(g.category, () => []).add(g);
    }

    // HOF: fold to compute weighted sum
    double totalWeight = 0;
    double weightedSum = grouped.entries.fold(0.0, (sum, entry) {
      final avgForCategory = entry.value
          .map((g) => g.percentage) // lambda: extract percentage
          .fold(0.0, (s, p) => s + p) /
          entry.value.length;
      final w = entry.key.weight;
      totalWeight += w;
      return sum + avgForCategory * w;
    });

    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  // Simple (unweighted) average — HOF: map + fold
  double get simpleAverage {
    if (_grades.isEmpty) return 0;
    return _grades.map((g) => g.percentage).fold(0.0, (a, b) => a + b) /
        _grades.length;
  }

  String get letterGrade => Grade._letterFromPercent(weightedAverage);

  // HOF: filter grades by predicate
  List<Grade> filterGrades(bool Function(Grade) predicate) =>
      _grades.where(predicate).toList();

  // HOF: sort grades by comparator
  List<Grade> sortGrades(int Function(Grade, Grade) comparator) =>
      [..._grades]..sort(comparator);

  // HOF: highest/lowest using reduce
  Grade? get highestGrade => _grades.isEmpty
      ? null
      : _grades.reduce((a, b) => a.percentage > b.percentage ? a : b);

  Grade? get lowestGrade => _grades.isEmpty
      ? null
      : _grades.reduce((a, b) => a.percentage < b.percentage ? a : b);

  // HOF: grades above threshold — returns a transformed list (map)
  List<String> gradesAbove(double threshold) => _grades
      .where((g) => g.percentage >= threshold) // filter
      .map((g) => '${g.title} (${g.percentage.toStringAsFixed(1)}%)') // transform
      .toList();

  bool get isPassing => weightedAverage >= 60;

  @override
  String toString() =>
      'Student($name, avg=${weightedAverage.toStringAsFixed(1)}%, $letterGrade)';
}

// ── GradeBook: manages multiple students ─────────────────────────────────────
class GradeBook {
  final String courseName;
  final List<Student> _students = [];

  GradeBook({required this.courseName});

  List<Student> get students => List.unmodifiable(_students);

  void addStudent(Student s) => _students.add(s);
  void removeStudent(String id) => _students.removeWhere((s) => s.id == id);

  Student? findById(String id) =>
      _students.where((s) => s.id == id).firstOrNull;

  // HOF: class average using map + fold
  double get classAverage {
    if (_students.isEmpty) return 0;
    return _students.map((s) => s.weightedAverage).fold(0.0, (a, b) => a + b) /
        _students.length;
  }

  // HOF: top N students using sort + take
  List<Student> topStudents(int n) => [..._students]
    ..sort((a, b) => b.weightedAverage.compareTo(a.weightedAverage))
    ..length; // chained — see below
  List<Student> topN(int n) {
    final sorted = [..._students]
      ..sort((a, b) => b.weightedAverage.compareTo(a.weightedAverage));
    return sorted.take(n).toList();
  }

  // HOF: filter passing / failing
  List<Student> get passingStudents =>
      _students.where((s) => s.isPassing).toList();
  List<Student> get failingStudents =>
      _students.where((s) => !s.isPassing).toList();

  // HOF: grade distribution using fold into a Map
  Map<String, int> get gradeDistribution =>
      _students.fold<Map<String, int>>({}, (map, s) {
        final letter = s.letterGrade;
        map[letter] = (map[letter] ?? 0) + 1;
        return map;
      });

  // Lambda: sort students by name
  List<Student> get sortedByName =>
      [..._students]..sort((a, b) => a.name.compareTo(b.name));

  // Lambda: sort students by grade descending
  List<Student> get sortedByGrade =>
      [..._students]..sort((a, b) => b.weightedAverage.compareTo(a.weightedAverage));
}
