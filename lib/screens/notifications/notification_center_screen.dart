import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:track_me/core/common_widgets.dart';
import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/data/models.dart';
import 'package:track_me/providers/app_state.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshNotifications();
    });
  }

  Future<void> _markRead(AppNotification n) async {
    if (!n.read) {
      await AppRepository.instance.markNotificationRead(n.id!);
      context.read<AppState>().refreshNotifications();
    }
  }

  Future<void> _markAll() async {
    await AppRepository.instance.markAllNotificationsRead();
    context.read<AppState>().refreshNotifications();
  }

  Future<void> _delete(AppNotification n) async {
    await AppRepository.instance.deleteNotification(n.id!);
    context.read<AppState>().refreshNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notifications = state.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.any((n) => !n.read))
            IconButton(
              tooltip: 'Mark all read',
              onPressed: _markAll,
              icon: const Icon(Icons.done_all),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Budget warnings, goal milestones and reminders will show up here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              itemCount: notifications.length,
              itemBuilder: (context, i) {
                final n = notifications[i];
                return _NotificationCard(
                  notification: n,
                  onTap: () => _markRead(n),
                  onDelete: () => _delete(n),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({required this.notification, required this.onTap, required this.onDelete});

  IconData get _icon {
    switch (notification.type) {
      case 'budget_exceeded':
        return Icons.warning_amber_rounded;
      case 'goal_completed':
        return Icons.celebration;
      case 'goal_milestone':
        return Icons.flag;
      case 'recurring':
        return Icons.autorenew;
      default:
        return Icons.info_outline;
    }
  }

  Color get _color {
    switch (notification.type) {
      case 'budget_exceeded':
        return AppColors.danger;
      case 'goal_completed':
        return AppColors.income;
      case 'goal_milestone':
        return AppColors.secondary;
      case 'recurring':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      color: n.read ? null : _color.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 22),
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
                        n.title,
                        style: TextStyle(
                          fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 13.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!n.read) Container(width: 8, height: 8, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.body, style: TextStyle(fontSize: 12.5, color: Theme.of(context).textTheme.bodySmall!.color), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Theme.of(context).textTheme.bodySmall!.color),
                    const SizedBox(width: 4),
                    Text(_timeAgo(n.createdAt), style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall!.color)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDateShort(iso);
  }
}