import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';

class TrainingPlanScreen extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String company, role;
  final int daysLeft;

  const TrainingPlanScreen({super.key, required this.plan, required this.company, required this.role, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final phases = List<Map<String, dynamic>>.from(plan['phases'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text('Plan for $company'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan['planTitle'] ?? 'Your Training Plan', style: const TextStyle(fontFamily: 'Syne', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(plan['summary'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 14),
                Row(children: [
                  _Stat(label: 'Days Left', value: '$daysLeft'),
                  const SizedBox(width: 16),
                  _Stat(label: 'Expected Gain', value: '+${plan['expectedPercentileGain'] ?? 0}%ile'),
                  const SizedBox(width: 16),
                  _Stat(label: 'Phases', value: '${phases.length}'),
                ]),
              ]),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Phases
            ...phases.asMap().entries.map((e) {
              final phase = e.value;
              final tasks = List<Map<String, dynamic>>.from(phase['tasks'] ?? []);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(phase['title'] ?? 'Phase ${e.key + 1}', style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(phase['days'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
                ]).animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 100)),

                const SizedBox(height: 10),

                ...tasks.asMap().entries.map((te) => _TaskCard(task: te.value).animate().fadeIn(delay: Duration(milliseconds: 300 + e.key * 100 + te.key * 60)).slideX(begin: 0.1)).toList(),
                const SizedBox(height: 16),
              ]);
            }).toList(),

            if (plan['finalTip'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.secondary.withOpacity(0.3))),
                child: Row(children: [const Icon(Icons.lightbulb_rounded, color: AppColors.secondary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Final Tip', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 14)), Text(plan['finalTip']!, style: const TextStyle(color: AppColors.lightMuted, fontSize: 13, height: 1.5))]))]),
              ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontFamily: 'Syne', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10))]);
}

class _TaskCard extends StatefulWidget {
  final Map<String, dynamic> task;
  const _TaskCard({required this.task});
  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 42),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _done ? AppColors.secondary.withOpacity(0.05) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _done ? AppColors.secondary.withOpacity(0.3) : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => setState(() => _done = !_done),
          child: Container(width: 24, height: 24, decoration: BoxDecoration(color: _done ? AppColors.secondary : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: _done ? AppColors.secondary : AppColors.lightMuted, width: 2)), child: _done ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(widget.task['day'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600))),
            const SizedBox(width: 6),
            Text('${widget.task['durationHours'] ?? 1}h', style: const TextStyle(fontSize: 10, color: AppColors.lightMuted)),
          ]),
          const SizedBox(height: 4),
          Text(widget.task['task'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, decoration: _done ? TextDecoration.lineThrough : null)),
          if (widget.task['resource'] != null) ...[const SizedBox(height: 4), Text('📚 ${widget.task['resource']}', style: const TextStyle(fontSize: 11, color: AppColors.lightMuted))],
        ])),
      ]),
    );
  }
}
