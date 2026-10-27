import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read after the first frame so the unread dots are visible briefly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Future.delayed(const Duration(seconds: 2), () {
        if (mounted) AppScope.read(context).markNotificationsRead();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = AppScope.of(context).notifications;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyState(icon: Icons.notifications_off_outlined, message: 'No notifications')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = items[index];
                return AppCard(
                  color: n.read ? null : AppColors.lavenderLight,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(n.read ? Icons.notifications_none : Icons.notifications_active,
                        color: AppColors.purple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(n.body, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(Fmt.relative(n.time), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
