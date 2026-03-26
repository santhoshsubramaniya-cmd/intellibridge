import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class GeminiService {
  late final GenerativeModel _model;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
  }

  Map<String, dynamic> _parseJson(String raw) {
    try {
      final clean = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(clean);
    } catch (_) {
      return {};
    }
  }

  // ─── 1. AI PROFILE ANALYSER ──────────────────────
  Future<Map<String, dynamic>> analyseStudentProfile(String userId) async {
    try {
      final studentDoc = await _db.collection('students').doc(userId).get();
      final userDoc = await _db.collection('users').doc(userId).get();
      final resultsSnap = await _db
          .collection('results')
          .where('studentEmail', isEqualTo: userDoc.data()?['email'] ?? '')
          .get();

      final student = studentDoc.data() ?? {};
      final user = userDoc.data() ?? {};
      final results = resultsSnap.docs.map((d) => d.data()).toList();

      final subjectMarks = <String, int>{};
      for (final r in results) {
        subjectMarks[r['subject'] ?? ''] = r['marks'] ?? 0;
      }

      double cgpa = (student['cgpa'] ?? 0.0).toDouble();
      if (results.isNotEmpty) {
        final avg = results
                .map((r) => (r['marks'] ?? 0) as int)
                .reduce((a, b) => a + b) /
            results.length;
        cgpa = double.parse((avg / 10).toStringAsFixed(1)).clamp(0.0, 10.0);
      }

      final prompt = '''
You are an AI career analyst. Analyse this student and return ONLY valid JSON, no markdown.

Student:
- Name: ${user['name']}
- Course: ${user['course']}
- Semester: ${user['semester']}
- CGPA: $cgpa
- Skills: ${(student['skills'] as List?)?.join(', ') ?? 'None'}
- Internships: ${(student['internships'] as List?)?.length ?? 0}
- Projects: ${student['projectCount'] ?? 0}
- Subject Marks: ${subjectMarks.entries.map((e) => '${e.key}:${e.value}').join(', ')}

Return exactly:
{
  "cgpa": $cgpa,
  "strongestDomain": "domain",
  "weakAreas": ["area1", "area2"],
  "suitableRoles": ["role1", "role2", "role3"],
  "readinessScore": 65,
  "topSkillsToLearn": ["skill1", "skill2", "skill3"],
  "profileSummary": "2 sentence honest assessment",
  "immediateAction": "single most important action",
  "hireabilityBreakdown": {
    "resumeStrength": 60,
    "skillReadiness": 55,
    "interviewReadiness": 40,
    "portfolioStrength": 35
  }
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = _parseJson(response.text ?? '{}');

      if (result.isNotEmpty) {
        await _db.collection('students').doc(userId).update({
          'cgpa': result['cgpa'] ?? cgpa,
          'strongestDomain': result['strongestDomain'],
          'weakAreas': result['weakAreas'] ?? [],
          'suitableRoles': result['suitableRoles'] ?? [],
          'hireabilityScore': (result['readinessScore'] ?? 0).toDouble(),
          'topSkillsToLearn': result['topSkillsToLearn'] ?? [],
          'profileSummary': result['profileSummary'],
          'immediateAction': result['immediateAction'],
          'hireabilityBreakdown': result['hireabilityBreakdown'],
          'lastAiAnalysis': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── 2. CAREER GAP ANALYSER ──────────────────────
  Future<Map<String, dynamic>> analyseCareerGap({
    required String userId,
    required String targetRole,
    required List<String> requiredSkills,
    required double minCgpa,
  }) async {
    try {
      final studentDoc = await _db.collection('students').doc(userId).get();
      final student = studentDoc.data() ?? {};
      final studentSkills = List<String>.from(student['skills'] ?? []);
      final cgpa = (student['cgpa'] ?? 0.0).toDouble();
      final internships = (student['internships'] as List?)?.length ?? 0;

      final prompt = '''
Analyse career gap. Return ONLY valid JSON, no markdown.

Student: CGPA $cgpa (need $minCgpa), Skills: ${studentSkills.join(', ')}, Internships: $internships
Target: $targetRole | Required: ${requiredSkills.join(', ')}

Return:
{
  "overallReadiness": 65,
  "skillGap": {"have": ["skill1"], "missing": ["skill2"]},
  "cgpaStatus": "meets",
  "experienceGap": "description",
  "weeksToReady": 6,
  "priorityActions": ["action1", "action2", "action3"]
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJson(response.text ?? '{}');
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── 3. AI TRAINING PLAN GENERATOR ──────────────
  Future<Map<String, dynamic>> generateTrainingPlan({
    required String userId,
    required String driveId,
    required String company,
    required String role,
    required List<String> requiredSkills,
    required int daysLeft,
  }) async {
    try {
      final studentDoc = await _db.collection('students').doc(userId).get();
      final student = studentDoc.data() ?? {};
      final studentSkills = List<String>.from(student['skills'] ?? []);
      final missingSkills =
          requiredSkills.where((s) => !studentSkills.contains(s)).toList();

      final prompt = '''
Create a $daysLeft-day training plan for $role at $company.
Missing skills: ${missingSkills.join(', ')}
Return ONLY valid JSON, no markdown.

{
  "planTitle": "Your plan for $company",
  "summary": "overview",
  "expectedPercentileGain": 15,
  "phases": [
    {
      "phase": 1,
      "title": "Phase title",
      "days": "Day 1-5",
      "focus": "focus area",
      "tasks": [
        {
          "day": "Day 1",
          "task": "Specific task",
          "resource": "Resource name",
          "resourceUrl": "https://leetcode.com",
          "durationHours": 2
        }
      ]
    }
  ],
  "mockInterviewDay": "Day ${daysLeft - 2}",
  "finalTip": "final tip"
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final plan = _parseJson(response.text ?? '{}');

      if (plan.isNotEmpty) {
        await _db.collection('training_plans').add({
          'userId': userId,
          'driveId': driveId,
          'company': company,
          'role': role,
          'plan': plan,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      return plan;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── 4. SMART ALERT GENERATOR ────────────────────
  Future<String> generatePlacementAlert({
    required String studentName,
    required String company,
    required String role,
    required int daysLeft,
    required double studentPercentile,
    required double requiredPercentile,
    required double readiness,
  }) async {
    try {
      final status = studentPercentile >= requiredPercentile
          ? 'QUALIFIES'
          : 'BELOW CUTOFF';

      final prompt = '''
Write a short placement alert (max 60 words). Friendly mentor tone, plain text only.

Student: $studentName | Company: $company | Role: $role
Drive in: $daysLeft days | Their percentile: ${studentPercentile.toStringAsFixed(0)}%
Required: ${requiredPercentile.toStringAsFixed(0)}% | Status: $status

Tell their status and ONE specific action for today.''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'New placement drive at $company!';
    } catch (e) {
      return 'New placement opportunity at $company for $role. Drive in $daysLeft days!';
    }
  }

  // ─── 5. CONTEXT-AWARE AI MENTOR CHAT ─────────────
  Future<String> careerMentorReply({
    required String userId,
    required String message,
    required List<Map<String, String>> chatHistory,
  }) async {
    try {
      final studentDoc = await _db.collection('students').doc(userId).get();
      final userDoc = await _db.collection('users').doc(userId).get();
      final student = studentDoc.data() ?? {};
      final user = userDoc.data() ?? {};

      final history = chatHistory
          .map((m) => Content(
                m['role'] == 'user' ? 'user' : 'model',
                [TextPart(m['text'] ?? '')],
              ))
          .toList();

      final systemContext = '''
You are SmartPlace AI Career Mentor — a personal, empathetic career advisor.
You know this student personally:
Name: ${user['name']} | Course: ${user['course']} | Semester: ${user['semester']}
CGPA: ${student['cgpa'] ?? 'Unknown'} | Skills: ${(student['skills'] as List?)?.join(', ') ?? 'None'}
Internships: ${(student['internships'] as List?)?.length ?? 0}
Suitable Roles: ${(student['suitableRoles'] as List?)?.join(', ') ?? 'Not analysed yet'}
Immediate Action: ${student['immediateAction'] ?? 'Run AI analysis first'}
Hireability: ${student['hireabilityScore'] ?? 0}%

Rules: Never generic advice. Always reference their specific profile. Under 100 words unless needed.

Student asks: $message''';

      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(systemContext));
      return response.text ?? 'I\'m here to help! Please try again.';
    } catch (e) {
      return 'Sorry, connection issue. Please try again!';
    }
  }

  // ─── 6. SKILL QUIZ GENERATOR ─────────────────────
  Future<List<Map<String, dynamic>>> generateSkillQuiz(String skill) async {
    try {
      final prompt = '''
Generate 5 MCQ questions to verify "$skill". Return ONLY JSON array, no markdown.
[{"question":"?","options":["A.","B.","C.","D."],"correct":"A","explanation":"why"}]''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '[]';
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final list = jsonDecode(clean) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ─── 7. LEARNING ROADMAP ─────────────────────────
  Future<Map<String, dynamic>> generateRoadmap({
    required String role,
    required List<String> currentSkills,
    required int weeks,
  }) async {
    try {
      final required = AppConstants.roleSkills[role] ?? [];
      final missing =
          required.where((s) => !currentSkills.contains(s)).toList();

      final prompt = '''
Create a $weeks-week roadmap for $role. Return ONLY valid JSON, no markdown.
Missing: ${missing.join(', ')} | Current: ${currentSkills.join(', ')}

{
  "title": "$weeks-Week Roadmap to $role",
  "summary": "overview",
  "phases": [
    {
      "phase": 1, "title": "name", "weeks": "Week 1-2", "color": "violet",
      "resources": [{"name":"Resource","type":"Course","url":"https://","emoji":"📚"}]
    }
  ]
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJson(response.text ?? '{}');
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
