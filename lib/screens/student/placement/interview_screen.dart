import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/gemini_service.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  final _gemini = GeminiService();
  String? _selectedRole;
  List<Map<String, dynamic>> _questions = [];
  int _currentQ = 0;
  bool _isLoading = false;
  bool _isEvaluating = false;
  bool _isCompleted = false;
  final _answerCtrl = TextEditingController();
  final List<Map<String, dynamic>> _answers = [];
  Map<String, dynamic>? _finalReport;

  final _roles = [
    'Software Engineer',
    'Data Analyst',
    'Data Scientist',
    'Full Stack Developer',
    'DevOps Engineer',
  ];

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _startInterview() async {
    if (_selectedRole == null) return;
    setState(() => _isLoading = true);
    final questions = await _gemini.generateInterviewQuestions(_selectedRole!);
    setState(() {
      _questions = questions;
      _currentQ = 0;
      _answers.clear();
      _isLoading = false;
    });
  }

  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    setState(() => _isEvaluating = true);

    final q = _questions[_currentQ];
    final eval = await _gemini.evaluateInterviewAnswer(
      question: q['q'] ?? '',
      hint: q['hint'] ?? '',
      answer: answer,
    );

    _answers.add({
      'question': q['q'],
      'type': q['type'],
      'answer': answer,
      'evaluation': eval,
    });
    _answerCtrl.clear();

    if (_currentQ < _questions.length - 1) {
      setState(() {
        _currentQ++;
        _isEvaluating = false;
      });
    } else {
      await _generateReport();
    }
  }

  Future<void> _generateReport() async {
    final avgScore = _answers
            .map((a) => (a['evaluation']?['overall'] ?? 0) as int)
            .reduce((a, b) => a + b) /
        _answers.length;

    final user = context.read<AuthService>().userModel;

    await FirebaseFirestore.instance.collection('interviews').add({
      'userId': user?.uid,
      'role': _selectedRole,
      'overallScore': avgScore.round(),
      'completedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _finalReport = {
        'overallScore': avgScore.round(),
        'role': _selectedRole,
        'interviewReadiness': avgScore >= 80
            ? 'High ✅'
            : avgScore >= 60
                ? 'Moderate ⚠️'
                : 'Needs Practice 📈',
      };
      _isCompleted = true;
      _isEvaluating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return _buildRoleSelect();
    if (_isCompleted) return _buildReport();
    return _buildInterview();
  }

  Widget _buildRoleSelect() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Interview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.secondary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.06),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Mock Interview 🎤',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('5 questions · AI evaluates each answer · Final readiness report',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.lightMuted, height: 1.5)),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),
            const Text('Choose Your Role',
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
                        ? AppColors.secondary.withOpacity(0.08)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? AppColors.secondary : AppColors.lightBorder,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.record_voice_over_rounded,
                        color: AppColors.secondary, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.secondary : null))),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.secondary),
                  ]),
                ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80)),
              );
            }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary),
                onPressed: _selectedRole == null || _isLoading ? null : _startInterview,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_isLoading ? 'Preparing questions...' : 'Start Interview'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterview() {
    final q = _questions[_currentQ];
    final progress = (_currentQ + 1) / _questions.length;
    final typeColor = q['type'] == 'Technical'
        ? AppColors.primary
        : q['type'] == 'HR'
            ? AppColors.secondary
            : AppColors.warning;

    return Scaffold(
      appBar: AppBar(
        title: Text('Q${_currentQ + 1} of ${_questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              backgroundColor: AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(q['type'] ?? '',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: typeColor)),
            ).animate().fadeIn(),

            const SizedBox(height: 14),
            Text(q['q'] ?? '',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, height: 1.4))
                .animate()
                .fadeIn(delay: 100.ms),

            const SizedBox(height: 20),
            const Text('Your Answer',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _answerCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                  hintText: 'Type your answer here. Be clear and specific...'),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEvaluating ? null : _submitAnswer,
                icon: _isEvaluating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_currentQ < _questions.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.done_rounded),
                label: Text(_isEvaluating
                    ? 'Evaluating...'
                    : _currentQ < _questions.length - 1
                        ? 'Next Question'
                        : 'Finish Interview'),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final score = _finalReport?['overallScore'] ?? 0;
    final color = score >= 80
        ? AppColors.secondary
        : score >= 60
            ? AppColors.warning
            : AppColors.accent;

    return Scaffold(
      appBar: AppBar(title: const Text('Interview Report')),
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
                const Text('Interview Complete! 🎉',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 1200),
                  builder: (_, v, __) => Text('$v%',
                      style: TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w800, color: color)),
                ),
                Text(_finalReport?['interviewReadiness'] ?? '',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              ]),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: 24),
            const Text('Question Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            ..._answers.asMap().entries.map((e) {
              final a = e.value;
              final eval = a['evaluation'] as Map<String, dynamic>? ?? {};
              final qScore = eval['overall'] ?? 0;
              final qColor = qScore >= 80
                  ? AppColors.secondary
                  : qScore >= 60
                      ? AppColors.warning
                      : AppColors.accent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: qColor.withOpacity(0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text('Q${e.key + 1}: ${a['question']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    Text('$qScore%',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: qColor)),
                  ]),
                  const SizedBox(height: 6),
                  Text(eval['feedback'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.lightMuted, height: 1.5)),
                ]),
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 100));
            }),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _questions.clear();
                  _selectedRole = null;
                  _isCompleted = false;
                  _finalReport = null;
                }),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
