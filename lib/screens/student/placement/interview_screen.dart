import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '../../../config/themes.dart';
import '../../../config/constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/gemini_service.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _gemini = GeminiService();
  String? _selectedRole;
  List<Map<String, dynamic>> _qaPairs = [];
  String? _currentQuestion;
  final _answerCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isEvaluating = false;
  bool _sessionComplete = false;
  Map<String, dynamic>? _sessionResult;
  int _questionNum = 0;
  final int _totalQuestions = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Interview'),
        actions: [
          if (_selectedRole != null && !_sessionComplete)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_questionNum/$_totalQuestions',
                  style: const TextStyle(
                      fontFamily: 'Syne', fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: _selectedRole == null
          ? _buildRoleSelector()
          : _sessionComplete
              ? _buildSessionResult()
              : _currentQuestion == null
                  ? _buildLoadingQuestion()
                  : _buildQuestionView(),
    );
  }

  Widget _buildRoleSelector() {
    final roles = [
      'Software Engineer',
      'Data Analyst',
      'Data Scientist',
      'Full Stack Developer',
      'DevOps Engineer',
      'Business Analyst',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.secondary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.08)
              ]),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.record_voice_over_rounded,
                    color: AppColors.secondary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI will ask you 5 interview questions and evaluate each answer with specific feedback.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          const Text('Select Interview Role',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),
          ...roles.asMap().entries.map((e) => GestureDetector(
                onTap: () => _startInterview(e.value),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                            Icons.record_voice_over_outlined,
                            color: AppColors.secondary,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.lightMuted),
                    ],
                  ),
                ).animate().fadeIn(
                    delay: Duration(milliseconds: 150 + e.key * 60)),
              )),
        ],
      ),
    );
  }

  Widget _buildLoadingQuestion() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 20),
          Text(
            'Preparing Question ${_questionNum + 1}...',
            style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _questionNum / _totalQuestions,
              backgroundColor: AppColors.lightBorder,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.secondary),
              minHeight: 6,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.secondary.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Q${_questionNum + 1} of $_totalQuestions',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _currentQuestion ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 20),

          const Text('Your Answer',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _answerCtrl,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText:
                  'Type your answer here. Be specific and structured...',
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary),
              onPressed: _isEvaluating ? null : _submitAnswer,
              icon: _isEvaluating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                  _isEvaluating ? 'Evaluating...' : 'Submit Answer'),
            ),
          ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }

  Widget _buildSessionResult() {
    final avgScore = _qaPairs.isEmpty
        ? 0
        : _qaPairs
                .map((q) => q['score'] as int? ?? 0)
                .reduce((a, b) => a + b) ~/
            _qaPairs.length;

    final color = avgScore >= 75
        ? AppColors.secondary
        : avgScore >= 50
            ? AppColors.warning
            : AppColors.accent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score hero
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
                  tween: IntTween(begin: 0, end: avgScore),
                  duration: const Duration(milliseconds: 1000),
                  builder: (_, val, __) => Text('$val%',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ),
                Text(
                  avgScore >= 75
                      ? 'Interview Ready! 🚀'
                      : avgScore >= 50
                          ? 'Good Progress ✅'
                          : 'Keep Practicing 📈',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                const SizedBox(height: 8),
                Text('$_totalQuestions questions answered for $_selectedRole',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.lightMuted)),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 24),
          const Text('Question-by-Question Review',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          ..._qaPairs.asMap().entries.map((e) {
            final qa = e.value;
            final score = qa['score'] as int? ?? 0;
            final qColor = score >= 75
                ? AppColors.secondary
                : score >= 50
                    ? AppColors.warning
                    : AppColors.accent;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: qColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Q${e.key + 1}',
                          style: const TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightMuted)),
                      const Spacer(),
                      Text('$score%',
                          style: TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w800,
                              color: qColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(qa['question'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(qa['feedback'] ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightMuted,
                          height: 1.5)),
                ],
              ),
            ).animate().fadeIn(
                delay: Duration(milliseconds: e.key * 100));
          }).toList(),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _selectedRole = null;
                _qaPairs = [];
                _currentQuestion = null;
                _sessionComplete = false;
                _questionNum = 0;
                _answerCtrl.clear();
              }),
              child: const Text('Start New Interview'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startInterview(String role) async {
    setState(() {
      _selectedRole = role;
      _isLoading = true;
    });
    await _nextQuestion();
  }

  Future<void> _nextQuestion() async {
    setState(() {
      _currentQuestion = null;
      _isLoading = true;
    });

    final previousQs =
        _qaPairs.map((q) => q['question'] as String).join(', ');

    try {
      final prompt = '''
Generate ONE unique interview question for a $_selectedRole role.
${previousQs.isNotEmpty ? 'Do NOT repeat these questions: $previousQs' : ''}
Question ${_questionNum + 1} of $_totalQuestions.

Respond ONLY with valid JSON (no markdown, no backticks):
{
  "question": "Your interview question here"
}
''';
      final resp = await _gemini.mentorReply(
        userId: '',
        message: prompt,
        studentData: {},
        chatHistory: [],
      );
      // Parse from response
      final clean = resp.replaceAll('```json', '').replaceAll('```', '').trim();
      try {
        final parsed = jsonDecode(clean);
        setState(() {
          _currentQuestion = parsed['question'] ?? resp;
          _isLoading = false;
        });
      } catch (_) {
        setState(() {
          _currentQuestion = resp;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentQuestion =
            'Explain a challenging project you have worked on and what you learned from it.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your answer')),
      );
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      final prompt = '''
Evaluate this interview answer for a $_selectedRole position.

Question: $_currentQuestion
Answer: ${_answerCtrl.text}

Respond ONLY with valid JSON (no markdown, no backticks):
{
  "score": 78,
  "feedback": "2-sentence specific feedback",
  "keywords": ["keyword1", "keyword2"],
  "missing": ["missing point 1", "missing point 2"]
}
''';
      final resp = await _gemini.mentorReply(
          userId: '', message: prompt, studentData: {}, chatHistory: []);
      final clean =
          resp.replaceAll('```json', '').replaceAll('```', '').trim();
      Map<String, dynamic> evaluation;
      try {
        evaluation = jsonDecode(clean) as Map<String, dynamic>;
      } catch (_) {
        evaluation = {'score': 70, 'feedback': resp, 'keywords': [], 'missing': []};
      }

      _qaPairs.add({
        'question': _currentQuestion,
        'answer': _answerCtrl.text,
        'score': evaluation['score'],
        'feedback': evaluation['feedback'],
      });

      _answerCtrl.clear();
      setState(() => _isEvaluating = false);

      if (_questionNum + 1 >= _totalQuestions) {
        setState(() {
          _questionNum++;
          _sessionComplete = true;
        });
      } else {
        setState(() => _questionNum++);
        await _nextQuestion();
      }
    } catch (e) {
      setState(() => _isEvaluating = false);
    }
  }
}
