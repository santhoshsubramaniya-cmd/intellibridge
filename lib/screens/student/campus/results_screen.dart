import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/note_model.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.getResultsForStudent(user?.email ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 64,
                      color: AppColors.lightMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No results yet',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your faculty will post results here',
                    style: TextStyle(
                        color: AppColors.lightMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Group by semester
          final docs = snapshot.data!.docs;
          final Map<int, List<ResultModel>> bySemester = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final result = ResultModel.fromMap(data, doc.id);
            bySemester
                .putIfAbsent(result.semester, () => [])
                .add(result);
          }

          // Calculate overall stats
          final allResults = docs.map((d) =>
              ResultModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id)).toList();
          final avgMarks = allResults.isEmpty
              ? 0.0
              : allResults.map((r) => r.marks).reduce((a, b) => a + b) /
                  allResults.length;
          final cgpa = (avgMarks / 10).clamp(0.0, 10.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats overview
                Row(
                  children: [
                    _StatBox(
                      label: 'CGPA',
                      value: cgpa.toStringAsFixed(1),
                      color: cgpa >= 7
                          ? AppColors.secondary
                          : cgpa >= 5
                              ? AppColors.warning
                              : AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'Avg Marks',
                      value: avgMarks.toStringAsFixed(0),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'Subjects',
                      value: allResults.length.toString(),
                      color: AppColors.warning,
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Semester-wise results
                ...bySemester.entries.map((entry) {
                  final sem = entry.key;
                  final results = entry.value;
                  final semAvg = results
                          .map((r) => r.marks)
                          .reduce((a, b) => a + b) /
                      results.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Semester $sem',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Syne',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Avg: ${semAvg.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.lightMuted),
                          ),
                        ],
                      ).animate().fadeIn(),
                      const SizedBox(height: 10),
                      ...results.map((r) => _ResultRow(result: r)
                          .animate()
                          .fadeIn()
                          .slideX(begin: 0.1)),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.lightMuted)),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ResultModel result;
  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.marks >= 75
        ? AppColors.secondary
        : result.marks >= 50
            ? AppColors.warning
            : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.subject,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          // Marks bar
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${result.marks}/100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: result.marks / 100,
                    backgroundColor:
                        color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                result.grade,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
