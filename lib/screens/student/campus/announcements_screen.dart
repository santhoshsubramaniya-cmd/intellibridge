// announcements_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/firestore_service.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64,
                      color: AppColors.lightMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No announcements yet',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _AnnouncementCard(
                title: data['title'] ?? 'Announcement',
                message: data['message'] ?? '',
                postedBy: data['postedBy'] ?? 'Faculty',
                postedAt: data['postedAt']?.toDate(),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 80))
                  .slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String message;
  final String postedBy;
  final DateTime? postedAt;

  const _AnnouncementCard({
    required this.title,
    required this.message,
    required this.postedBy,
    this.postedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
                fontSize: 13, height: 1.6, color: AppColors.lightMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.lightMuted),
              const SizedBox(width: 4),
              Text(
                postedBy,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.lightMuted),
              ),
              const Spacer(),
              if (postedAt != null)
                Text(
                  '${postedAt!.day}/${postedAt!.month}/${postedAt!.year}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.lightMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
