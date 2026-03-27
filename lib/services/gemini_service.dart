import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel model;

  GeminiService() {
    model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
  }

  Future<Map<String, dynamic>> analyseStudentProfile(String userId, Map<String, dynamic> data) async {
    try {
      final prompt = """
You are SmartPlace AI. Analyse this student. ONLY valid JSON, no markdown, no backticks:
{
  "strongestDomain": "e.g. Data Science",
  "weakAreas": ["area1", "area2"],
  "suitableRoles": ["role1", "role2"],
  "readinessScore": 72,
  "topActions": ["action1", "action2", "action3"],
  "profileSummary": "2-sentence summary",
  "studyPattern": "Consistent",
  "marketDemand": "High"
}

CGPA: ${data['cgpa']}, Skills: ${(data['skills'] as List?)?.join(', ') ?? 'None'},
Internships: ${(data['internships'] as List?)?.length ?? 0}, Projects: ${data['projectCount'] ?? 0}
""";
      return _json(await _call(prompt));
    } catch (_) {
      return {'strongestDomain': 'Analysing...', 'weakAreas': [], 'suitableRoles': ['Software Engineer'],
        'readinessScore': 0, 'topActions': ['Complete profile', 'Add skills'],
        'profileSummary': 'Add more data for AI analysis.', 'studyPattern': 'Unknown', 'marketDemand': 'Medium'};
    }
  }

  Future<Map<String, dynamic>> calculateHireability(Map<String, dynamic> data) async {
    final cgpa = (data['cgpa'] ?? 0.0) as double;
    final skills = (data['skills'] as List?)?.length ?? 0;
    final internships = (data['internships'] as List?)?.length ?? 0;
    final projects = data['projectCount'] ?? 0;
    final certs = data['certCount'] ?? 0;
    final attendance = (data['attendance'] ?? 0) as int;

    final resumeScore = ((cgpa / 10 * 40) + (projects * 10).clamp(0, 40) + (certs * 5).clamp(0, 20)).round().clamp(0, 100);
    final skillScore = (skills / 10 * 100).round().clamp(0, 100);
    final interviewScore = ((cgpa / 10 * 60) + (certs * 10).clamp(0, 40)).round().clamp(0, 100);
    final portfolioScore = ((projects * 15).clamp(0, 60) + (internships * 20).clamp(0, 40)).clamp(0, 100);
    final attendanceScore = attendance.clamp(0, 100);
    final total = ((resumeScore * 0.25) + (skillScore * 0.25) + (interviewScore * 0.20) + (portfolioScore * 0.20) + (attendanceScore * 0.10)).round().clamp(0, 100);

    return {'resumeScore': resumeScore, 'skillScore': skillScore, 'interviewScore': interviewScore,
      'portfolioScore': portfolioScore, 'attendanceScore': attendanceScore, 'total': total};
  }

  Future<Map<String, dynamic>> generateTrainingPlan({
    required Map<String, dynamic> studentData,
    required String company,
    required String role,
    required List<String> skillGaps,
    required int daysLeft,
  }) async {
    try {
      final prompt = """
Generate personalised training plan. ONLY valid JSON, no markdown:
{
  "phases": [{"phase": "Phase 1", "days": "Day 1-7", "focus": "skill", "tasks": ["task1"],
    "resources": [{"name": "res", "url": "https://leetcode.com", "type": "Practice"}], "expectedGain": "+5 percentile"}],
  "projectedPercentile": 72, "totalPhases": 3, "summary": "summary"
}
Target: $role at $company. Days: $daysLeft. Missing: ${skillGaps.join(', ')}.
Current skills: ${(studentData['skills'] as List?)?.join(', ') ?? 'None'}.
Create ${(daysLeft / 7).ceil()} phases. Use real resources (LeetCode, Coursera, freeCodeCamp).
""";
      return _json(await _call(prompt));
    } catch (_) {
      return {
        'phases': [{'phase': 'Phase 1', 'days': 'Day 1-$daysLeft',
          'focus': skillGaps.isNotEmpty ? skillGaps[0] : 'Core Skills',
          'tasks': ['Study fundamentals', 'Practice problems'],
          'resources': [{'name': 'LeetCode', 'url': 'https://leetcode.com', 'type': 'Practice'}],
          'expectedGain': '+10 percentile'}],
        'projectedPercentile': 60, 'totalPhases': 1, 'summary': 'Focus on skill gaps.'
      };
    }
  }

  Future<String> generateSmartAlert({
    required String studentName, required String company,
    required int currentPercentile, required int requiredPercentile,
    required int daysLeft, required List<String> skillGaps,
  }) async {
    try {
      final eligible = currentPercentile >= requiredPercentile;
      final prompt = "Write a SHORT placement alert (max 60 words). Friendly mentor tone. Plain text only.\n"
          "Student: $studentName, Company: $company, Percentile: $currentPercentile%, Required: $requiredPercentile%, "
          "Days: $daysLeft, ${eligible ? 'ELIGIBLE ✅' : '${requiredPercentile - currentPercentile}% below ⚠️'}, "
          "Missing: ${skillGaps.take(2).join(', ')}";
      return await _call(prompt);
    } catch (_) {
      return currentPercentile >= requiredPercentile
          ? 'Great news! You qualify for $company in $daysLeft days!'
          : 'You are ${requiredPercentile - currentPercentile}% below $company cutoff. Follow your AI plan!';
    }
  }

  Future<String> mentorReply({
    required String userId, required String message,
    required Map<String, dynamic> studentData,
    required List<Map<String, dynamic>> chatHistory,
  }) async {
    try {
      final history = chatHistory.take(6).map((m) => '${m['role'] == 'user' ? 'Student' : 'AI'}: ${m['text']}').join('\n');
      final prompt = "You are SmartPlace AI — a personal placement mentor.\n"
          "CGPA: ${studentData['cgpa']}, Skills: ${(studentData['skills'] as List?)?.join(', ') ?? 'None'}, "
          "Hireability: ${studentData['hireabilityScore']}%, Strongest: ${studentData['strongestDomain'] ?? 'Unknown'}\n"
          "Recent chat:\n$history\nStudent: $message\nReply as mentor. Specific. Max 80 words. Plain text.";
      return await _call(prompt);
    } catch (_) {
      return "I'm having trouble connecting. Please try again.";
    }
  }

  Future<Map<String, dynamic>> evaluateSimulation({
    required String role, required String taskTitle,
    required String taskDescription, required String taskContent,
    required String instructions, required String candidateAnswer,
  }) async {
    try {
      final prompt = """
Evaluate simulation answer. ONLY valid JSON, no markdown:
{"overallScore": 78, "accuracy": 80, "clarity": 75, "completeness": 76,
 "feedback": "2-3 sentence feedback", "strengths": ["s1"], "improvements": ["i1"], "grade": "B+"}
Role: $role, Task: $taskTitle, Instructions: $instructions, Answer: $candidateAnswer
""";
      return _json(await _call(prompt));
    } catch (_) {
      return {'overallScore': 70, 'accuracy': 70, 'clarity': 70, 'completeness': 70,
        'feedback': 'Good attempt!', 'strengths': ['Attempted task'], 'improvements': ['Add detail'], 'grade': 'B'};
    }
  }

  Future<List<Map<String, dynamic>>> generateInterviewQuestions(String role) async {
    try {
      final prompt = "Generate 5 interview questions for $role fresher. Mix: 2 technical, 1 coding, 1 situational, 1 HR.\n"
          "ONLY valid JSON array, no markdown: [{\"q\": \"question\", \"type\": \"Technical\", \"hint\": \"coverage\"}]";
      final raw = _list(await _call(prompt));
      return List<Map<String, dynamic>>.from(raw);
    } catch (_) {
      return [
        {'q': 'Tell me about yourself.', 'type': 'HR', 'hint': 'Background, skills, goals'},
        {'q': 'Explain OOP concepts.', 'type': 'Technical', 'hint': 'Encapsulation, inheritance, polymorphism'},
        {'q': 'What is the difference between a list and tuple in Python?', 'type': 'Technical', 'hint': 'Mutability'},
        {'q': 'Describe a challenging project.', 'type': 'Situational', 'hint': 'Problem, solution, learnings'},
        {'q': 'Where do you see yourself in 2 years?', 'type': 'HR', 'hint': 'Career goals'},
      ];
    }
  }

  Future<Map<String, dynamic>> evaluateInterviewAnswer({
    required String question, required String hint, required String answer,
  }) async {
    try {
      final prompt = "Evaluate interview answer. ONLY valid JSON, no markdown:\n"
          "{\"relevance\": 80, \"clarity\": 75, \"depth\": 70, \"overall\": 75, "
          "\"feedback\": \"one sentence\", \"missingPoints\": [\"point1\"]}\n"
          "Question: $question, Should cover: $hint, Answer: $answer";
      return _json(await _call(prompt));
    } catch (_) {
      return {'relevance': 70, 'clarity': 70, 'depth': 70, 'overall': 70,
        'feedback': 'Good attempt!', 'missingPoints': ['More examples', 'Technical depth']};
    }
  }

  Future<Map<String, dynamic>> analyseCareerGap(Map<String, dynamic> data, String role) async {
    try {
      final prompt = "Analyse career gap. ONLY valid JSON, no markdown:\n"
          "{\"overallReadiness\": 65, \"skillGaps\": [\"s1\"], \"experienceGaps\": [\"e1\"], "
          "\"projectGaps\": [\"p1\"], \"estimatedWeeks\": 6, \"priorityActions\": [\"a1\"], \"matchedSkills\": [\"m1\"]}\n"
          "Skills: ${(data['skills'] as List?)?.join(', ')}, CGPA: ${data['cgpa']}, Role: $role";
      return _json(await _call(prompt));
    } catch (_) {
      return {'overallReadiness': 50, 'skillGaps': [], 'estimatedWeeks': 8, 'priorityActions': [], 'matchedSkills': []};
    }
  }

  // ─── Helpers ──────────────────────────────────────────
  Future<String> _call(String prompt) async {
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  Map<String, dynamic> _json(String text) {
    try {
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  List<dynamic> _list(String text) {
    try {
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }
}
