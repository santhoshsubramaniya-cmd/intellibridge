import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/gemini_service.dart';
import 'dart:convert';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _fs = FirestoreService();
  final _gemini = GeminiService();
  bool _isGenerating = false;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('portfolio')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _entries =
          snap.docs.map((d) => d.data()).toList();
    });
  }

  Future<void> _generatePortfolio() async {
    final user = context.read<AuthService>().userModel;
    if (user == null) return;
    setState(() => _isGenerating = true);

    final profile = await _fs.getStudentProfile(user.uid);
    final data = profile?.toMap() ?? {};

    final prompt = '''
Generate a professional portfolio summary for this student.

Profile:
- CGPA: ${data['cgpa']}
- Skills: ${(data['skills'] as List?)?.join(', ') ?? 'None'}
- Internships: ${(data['internships'] as List?)?.length ?? 0}
- Projects: ${data['projectCount'] ?? 0}
- Hireability Score: ${data['hireabilityScore']}%

Respond ONLY with valid JSON (no markdown, no backticks):
{
  "headline": "Professional headline (10 words max)",
  "summary": "2-3 sentence professional summary",
  "strengths": ["strength 1", "strength 2", "strength 3"],
  "resumeBullets": ["• Achieved X by doing Y resulting in Z", "• Built X using Y for Z purpose"],
  "linkedinAbout": "LinkedIn About section (100 words)"
}
''';

    try {
      final reply = await _gemini.mentorReply(
          userId: user.uid,
          message: prompt,
          studentData: data,
          chatHistory: []);

      final clean =
          reply.replaceAll('```json', '').replaceAll('```', '').trim();
      import 'dart:convert';
      final parsed = jsonDecode(clean) as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('portfolio').add({
        'userId': user.uid,
        'type': 'ai_generated',
        'headline': parsed['headline'],
        'summary': parsed['summary'],
        'strengths': parsed['strengths'],
        'resumeBullets': parsed['resumeBullets'],
        'linkedinAbout': parsed['linkedinAbout'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadPortfolio();
    } catch (e) {
      // fallback
    }

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        actions: [
          TextButton.icon(
            onPressed: _isGenerating ? null : _generatePortfolio,
            icon: _isGenerating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.primary),
            label: const Text('Generate',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: _entries.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, i) =>
                  _PortfolioCard(entry: _entries[i])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 100))
                      .slideY(begin: 0.1),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline_rounded,
                size: 64, color: AppColors.lightMuted),
            const SizedBox(height: 16),
            const Text('No portfolio yet',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Tap "Generate" to create your AI-powered portfolio',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.lightMuted, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePortfolio,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Generate AI Portfolio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _PortfolioCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final strengths = List<String>.from(entry['strengths'] ?? []);
    final bullets = List<String>.from(entry['resumeBullets'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder),
      ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text('AI Generated Portfolio',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(entry['headline'] ?? '',
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(entry['summary'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.lightMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (strengths.isNotEmpty) ...[
                  const Text('Key Strengths',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: strengths
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.secondary
                                        .withOpacity(0.25)),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (bullets.isNotEmpty) ...[
                  const Text('Resume Bullets',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  ...bullets.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(b,
                            style: const TextStyle(
                                fontSize: 13, height: 1.5)),
                      )),
                  const SizedBox(height: 16),
                ],
                if (entry['linkedinAbout'] != null) ...[
                  const Text('LinkedIn About',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(entry['linkedinAbout'] ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.lightMuted,
                          height: 1.6)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
