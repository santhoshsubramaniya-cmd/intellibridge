import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/gemini_service.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _gemini = GeminiService();
  String? _selectedRole;
  Map<String, dynamic>? _task;
  bool _isSubmitting = false;
  bool _isCompleted = false;
  Map<String, dynamic>? _result;
  final _answerCtrl = TextEditingController();

  final _roles = [
    'Software Engineer',
    'Data Analyst',
    'Full Stack Developer',
    'DevOps Engineer',
    'Business Analyst',
  ];

  final _tasks = {
    'Software Engineer': {
      'title': 'Fix the Bug 🐛',
      'description': 'A user reports the login function throws an error. Find and fix it.',
      'content': '''def login(username, password):
  users = {"admin": "pass123", "user1": "abc"}
  if username in users:
    if users[username] == password
      return "Login successful"
  return "Login failed"''',
      'instructions':
          'Identify the syntax error, explain why it causes a problem, and write the corrected code.',
    },
    'Data Analyst': {
      'title': 'Analyse This Dataset 📊',
      'description': 'You are given monthly sales data. Answer the analysis questions below.',
      'content': '''Month    | Sales (₹)  | Units | Region
---------|------------|-------|--------
January  | 4,50,000   | 150   | North
February | 3,20,000   | 105   | South
March    | 5,80,000   | 195   | North
April    | 2,90,000   | 96    | East
May      | 6,10,000   | 204   | West
June     | 4,80,000   | 160   | South''',
      'instructions':
          '1. Which month had highest revenue?\n2. Best performing region?\n3. Average sales per unit?\n4. Give 2 business recommendations.',
    },
    'Full Stack Developer': {
      'title': 'Design a REST API 🔌',
      'description': 'Design a REST API for a student profile system supporting CRUD operations.',
      'content': 'System needs: Create student, Get by ID, Update skills, Delete student.',
      'instructions':
          'Define HTTP methods, endpoint URLs, request body, and response format for all 4 operations.',
    },
    'DevOps Engineer': {
      'title': 'Write a Dockerfile 🐳',
      'description': 'Containerise a Python Flask application.',
      'content': 'App: port 5000, Python 3.10, has requirements.txt, main file is app.py.',
      'instructions': 'Write a complete Dockerfile and explain each instruction.',
    },
    'Business Analyst': {
      'title': 'Solve a Business Problem 💼',
      'description': "An e-commerce company's cart abandonment rate is 68%.",
      'content':
          'Conversion: 32%. Industry avg: 65%. Top reasons: high shipping (45%), forced account (30%), slow checkout (25%).',
      'instructions':
          '1. Identify top priority issue\n2. Propose 3 solutions with expected impact\n3. Define success metrics\n4. Prioritise your solutions.',
    },
  };

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return _buildRoleSelect();
    if (_isCompleted) return _buildResult();
    return _buildTask();
  }

  Widget _buildRoleSelect() {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Simulation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.08),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Real Job Simulation 🧪',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text(
                      'Complete real work tasks for your target role. AI evaluates and scores your submission.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.lightMuted, height: 1.5)),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),
            const Text('Select a Role',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            ..._roles.asMap().entries.map((e) {
              final selected = _selectedRole == e.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = e.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.08)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? AppColors.primary : AppColors.lightBorder,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.computer_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.primary : null))),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary),
                  ]),
                ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80)),
              );
            }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedRole == null
                    ? null
                    : () => setState(() => _task = _tasks[_selectedRole]),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Simulation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTask() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task!['title']),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _task = null;
              _answerCtrl.clear();
            }),
            child: const Text('New Task',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_task!['description'],
                style: const TextStyle(fontSize: 14, height: 1.6))
                .animate()
                .fadeIn(),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(_task!['content'],
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.secondary,
                      height: 1.6)),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Task:',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(_task!['instructions'],
                      style: const TextStyle(fontSize: 13, height: 1.6)),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),
            const Text('Your Answer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _answerCtrl,
              maxLines: 10,
              decoration:
                  const InputDecoration(hintText: 'Write your answer here...'),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                    _isSubmitting ? 'AI is evaluating...' : 'Submit for AI Evaluation'),
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_answerCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    final user = context.read<AuthService>().userModel;

    final result = await _gemini.evaluateSimulation(
      role: _selectedRole!,
      taskTitle: _task!['title'],
      taskDescription: _task!['description'],
      taskContent: _task!['content'],
      instructions: _task!['instructions'],
      candidateAnswer: _answerCtrl.text.trim(),
    );

    await FirebaseFirestore.instance.collection('simulations').add({
      'userId': user?.uid,
      'role': _selectedRole,
      'taskTitle': _task!['title'],
      'score': result['overallScore'],
      'grade': result['grade'],
      'completedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _result = result;
      _isCompleted = true;
      _isSubmitting = false;
    });
  }

  Widget _buildResult() {
    final score = _result!['overallScore'] ?? 0;
    final color = score >= 80
        ? AppColors.secondary
        : score >= 60
            ? AppColors.warning
            : AppColors.accent;

    return Scaffold(
      appBar: AppBar(title: const Text('Simulation Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.12), color.withOpacity(0.04)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(children: [
                Text('Simulation Complete! 🎯',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 12),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 1200),
                  builder: (_, v, __) => Text('$v%',
                      style: TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w800, color: color)),
                ),
                Text(_result!['grade'] ?? '',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              ]),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 20),
            Row(children: [
              _pill('Accuracy', _result!['accuracy'] ?? 0, AppColors.primary),
              const SizedBox(width: 8),
              _pill('Clarity', _result!['clarity'] ?? 0, AppColors.secondary),
              const SizedBox(width: 8),
              _pill('Complete', _result!['completeness'] ?? 0, AppColors.warning),
            ]).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AI Feedback',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Text(_result!['feedback'] ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.6)),
                const SizedBox(height: 12),
                _feedbackList('Strengths ✅',
                    List<String>.from(_result!['strengths'] ?? []),
                    AppColors.secondary),
                const SizedBox(height: 8),
                _feedbackList('Improve 📈',
                    List<String>.from(_result!['improvements'] ?? []),
                    AppColors.warning),
              ]),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => setState(
                          () { _isCompleted = false; _answerCtrl.clear(); }),
                      child: const Text('Try Again'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => setState(() {
                            _task = null;
                            _isCompleted = false;
                            _selectedRole = null;
                          }),
                      child: const Text('New Role'))),
            ]).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, int score, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Text('$score%',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.lightMuted)),
          ]),
        ),
      );

  Widget _feedbackList(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 6),
      ...items.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 5, right: 8),
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              Expanded(child: Text(i, style: const TextStyle(fontSize: 12))),
            ]),
          )),
    ]);
  }
}
