import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/themes.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_sevice.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read',
                style: TextStyle(
                    color: AppColors.primary, fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.getAlertsForUser(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_outlined,
                      size: 64,
                      color: AppColors.lightMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No alerts yet',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                      'Placement alerts will appear here',
                      style: TextStyle(
                          color: AppColors.lightMuted, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;

              return _AlertCard(
                id: doc.id,
                type: data['type'] ?? 'info',
                title: data['title'] ?? '',
                message: data['message'] ?? '',
                isRead: isRead,
                createdAt: data['createdAt']?.toDate(),
                onTap: () => fs.markAlertRead(doc.id),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 80))
                  .slideX(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final VoidCallback onTap;

  const _AlertCard({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    required this.onTap,
  });

  Color get _typeColor {
    switch (type) {
      case 'placement_drive':
        return AppColors.primary;
      case 'warning':
        return AppColors.warning;
      case 'success':
        return AppColors.secondary;
      case 'broadcast':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case 'placement_drive':
        return Icons.work_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'broadcast':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? Theme.of(context).cardColor
              : _typeColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder)
                : _typeColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(_typeIcon, color: _typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightMuted,
                        height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.lightMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
