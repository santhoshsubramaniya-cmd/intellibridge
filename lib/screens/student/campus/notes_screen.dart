import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/note_model.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final fs = FirestoreService();
    final course = user?.course ?? '';
    final semester = user?.semester ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Notes'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  course.isEmpty
                      ? 'Notes for your course will appear here'
                      : 'Notes for $course · Semester $semester',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // FIX: query without orderBy — we sort client-side below
              stream: fs.getNotesForStudent(course, semester),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.accent),
                        const SizedBox(height: 12),
                        Text('Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.lightMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 64,
                            color: AppColors.lightMuted.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('No notes uploaded yet',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Your faculty will upload notes here',
                            style: TextStyle(
                                color: AppColors.lightMuted, fontSize: 13)),
                        if (course.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                              'Make sure your profile has a course selected',
                              style: TextStyle(
                                  color: AppColors.warning, fontSize: 12)),
                        ],
                      ],
                    ),
                  );
                }

                // Sort client-side by uploadedAt descending
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final at =
                        (a.data() as Map)['uploadedAt'] as Timestamp?;
                    final bt =
                        (b.data() as Map)['uploadedAt'] as Timestamp?;
                    if (at == null || bt == null) return 0;
                    return bt.compareTo(at);
                  });

                final notes = docs
                    .map((d) => NoteModel.fromMap(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, i) => _NoteCard(note: notes[i])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 80))
                      .slideX(begin: 0.1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded,
              color: AppColors.accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.title,
                  style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('By ${note.uploadedBy} · Sem ${note.semester}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.lightMuted)),
              if (note.skillTags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: note.skillTags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            if (note.fileUrl.isNotEmpty) {
              final uri = Uri.parse(note.fileUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.download_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}
