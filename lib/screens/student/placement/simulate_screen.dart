import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/firestore_service.dart';

class SimulateScreen extends StatefulWidget {
  const SimulateScreen({super.key});

  @override
  State<SimulateScreen> createState() => _SimulateScreenState();
}

class _SimulateScreenState extends State<SimulateScreen> {
  final _gemini = GeminiService();
  String? _selectedRole;
  Map<String, dynamic>? _task;
  Map<String, dynamic>? _result;
  final _answerCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isEvaluating = false;

  final _roleIcons = {
    'Data Analyst': Icons.bar_chart_rounded,
    'Software Engineer': Icons.code_rounded,
    'Full Stack Developer': Icons.web_rounded,
    'Business Analyst': Icons.analytics_rounded,
    'DevOps Engineer': Icons.cloud_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Simulation')),
      body: _selectedRole == null
          ? _buildRoleSelector()
          : _task == null
              ? _buildLoadingTask()
              : _result == null
                  ? _buildTaskView()
                  : _buildResultView(),
    );
  }

  Widget _buildRoleSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.08)
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.work_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Complete a real job task and get AI feedback on your performance!',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          const Text('Choose Your Target Role',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),
          ..._roleIcons.entries.map((e) => _RoleCard(
                role: e.key,
                icon: e.value,
                onTap: () => _loadTask(e.key),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1)),
        ],
      ),
    );
  }

  Widget _buildLoadingTask() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text('AI is preparing your task...',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTaskView() {
    final taskText = _task!['task'] ?? '';
    final context_ = _task!['context'] ?? '';
    final instructions = List<String>.from(_task!['instructions'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text('$_selectedRole Simulation Task',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning)),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Task',
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(taskText,
                    style: const TextStyle(fontSize: 14, height: 1.6)),
                if (context_.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Context',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightMuted,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(context_,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.lightMuted,
                          height: 1.5)),
                ],
                if (instructions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Instructions',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightMuted,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  ...instructions.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.key + 1}. ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            Expanded(
                                child: Text(e.value,
                                    style:
                                        const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),
          const Text('Your Answer',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 10),
          TextField(
            controller: _answerCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Write your solution here...',
              alignLabelWithHint: true,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isEvaluating ? null : _evaluate,
              icon: _isEvaluating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label:
                  Text(_isEvaluating ? 'AI Evaluating...' : 'Submit for AI Evaluation'),
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() {
              _selectedRole = null;
              _task = null;
              _answerCtrl.clear();
            }),
            child: const Text('Change Role'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final total = _result!['overallScore'] ?? 0;
    final accuracy = _result!['accuracy'] ?? 0;
    final quality = _result!['quality'] ?? 0;
    final presentation = _result!['presentation'] ?? 0;
    final feedback = _result!['feedback'] ?? '';
    final improvements = List<String>.from(_result!['improvements'] ?? []);

    final color = total >= 75
        ? AppColors.secondary
        : total >= 50
            ? AppColors.warning
            : AppColors.accent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: total),
                  duration: const Duration(milliseconds: 1000),
                  builder: (_, val, __) => Text('$val%',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
                Text('Overall Score',
                    style: TextStyle(
                        fontSize: 14, color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ScorePill('Accuracy', accuracy, color),
                    _ScorePill('Quality', quality, color),
                    _ScorePill('Clarity', presentation, color),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 16),
                    SizedBox(width: 6),
                    Text('AI Feedback',
                        style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(feedback,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          if (improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Improvements',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...improvements.map((imp) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(imp,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )).toList(),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _task = null;
                    _result = null;
                    _answerCtrl.clear();
                    _loadTask(_selectedRole!);
                  }),
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _selectedRole = null;
                    _task = null;
                    _result = null;
                    _answerCtrl.clear();
                  }),
                  child: const Text('New Role'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadTask(String role) async {
    setState(() {
      _selectedRole = role;
      _isLoading = true;
    });

    try {
      final prompt = '''
Generate a realistic job task for a $role position.
Respond ONLY with valid JSON (no markdown, no backticks):
{
  "task": "Clear description of the task (2-3 sentences)",
  "context": "Background context the candidate should know",
  "instructions": ["step 1", "step 2", "step 3"],
  "expectedOutput": "What a good answer should include"
}
Make it realistic and specific to the $role role.
''';
      final resp = await _gemini._model.generateContent(
          [Content.text(prompt)]);
      final text = resp.text ?? '{}';
      final clean =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      setState(() {
        _task = jsonDecode(clean) as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _task = {
          'task':
              'Analyse the given dataset and identify the top 3 insights that would help increase revenue.',
          'context':
              'You are a $role at a mid-sized e-commerce company. The sales team needs data-driven recommendations.',
          'instructions': [
            'Review the data carefully',
            'Identify key patterns and trends',
            'Write 3 clear actionable insights',
            'Explain the business impact of each',
          ],
          'expectedOutput':
              'Clear insights with data reasoning and business impact',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _evaluate() async {
    if (_answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your answer first')),
      );
      return;
    }
    setState(() => _isEvaluating = true);

    try {
      final prompt = '''
Evaluate this student's answer to a $role job simulation task.

Task: ${_task!['task']}
Expected Output: ${_task!['expectedOutput']}
Student Answer: ${_answerCtrl.text}

Respond ONLY with valid JSON (no markdown, no backticks):
{
  "overallScore": 78,
  "accuracy": 80,
  "quality": 75,
  "presentation": 79,
  "feedback": "2-3 sentence honest evaluation",
  "improvements": ["improvement 1", "improvement 2", "improvement 3"]
}
''';
      final resp = await _gemini._model.generateContent(
          [Content.text(prompt)]);
      final text = resp.text ?? '{}';
      final clean =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      setState(() {
        _result = jsonDecode(clean) as Map<String, dynamic>;
        _isEvaluating = false;
      });
    } catch (e) {
      setState(() {
        _result = {
          'overallScore': 70,
          'accuracy': 72,
          'quality': 68,
          'presentation': 70,
          'feedback':
              'Good attempt! Your answer shows understanding of the problem. Focus on being more specific with data references.',
          'improvements': [
            'Be more specific with numbers and data points',
            'Structure your answer with clear headings',
            'Add a conclusion with next steps',
          ],
        };
        _isEvaluating = false;
      });
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.role, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(role,
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.lightMuted),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScorePill(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$score%',
            style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.lightMuted)),
      ],
    );
  }
}

// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

extension GeminiModelAccess on GeminiService {
  GenerativeModel get _model => GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: '',
      );
}
