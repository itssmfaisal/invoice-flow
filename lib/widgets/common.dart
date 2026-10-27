import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../screens/notifications_screen.dart';
import '../state/app_state.dart';

const pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 28);

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Color statusColor(InvoiceStatus status) => switch (status) {
      InvoiceStatus.pendingApproval => AppColors.amber,
      InvoiceStatus.approved => AppColors.green,
      InvoiceStatus.financed => AppColors.purple,
      InvoiceStatus.paid => AppColors.blue,
      InvoiceStatus.rejected => AppColors.red,
    };

IconData roleIcon(UserRole role) => switch (role) {
      UserRole.buyer => Icons.business_center_outlined,
      UserRole.supplier => Icons.storefront_outlined,
      UserRole.lender => Icons.account_balance_outlined,
    };

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        'InvoiceFlow',
        style: TextStyle(color: AppColors.purple, fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -0.6),
      );
}

/// Top of every main tab: brand, notification bell and page title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final unread = state.unreadNotifications;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(),
            const Spacer(),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none_rounded, color: AppColors.purple),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.lavender,
              child: Text(state.user?.initials ?? '',
                  style: const TextStyle(color: AppColors.purpleDark, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// White rounded panel with a light border.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color == null ? AppColors.line : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Lavender metric tile, like the cards on the dashboard design.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent = AppColors.purple,
    this.change,
    this.caption,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  /// Change versus the previous period (0.152 = +15.2%).
  final double? change;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.lavenderLight, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              if (icon != null) Icon(icon, size: 18, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: accent, fontSize: 21, fontWeight: FontWeight.w900)),
          ),
          if (change != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 13, color: change >= 0 ? AppColors.green : AppColors.red),
              Text(' ${Fmt.signedPercent(change)}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: change >= 0 ? AppColors.green : AppColors.red)),
            ]),
          ],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

/// Lays out children two per row, sized to the screen width.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    });
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 3)],
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) => Pill(label: status.label, color: statusColor(status));
}

class InvoiceTile extends StatelessWidget {
  const InvoiceTile({super.key, required this.invoice, this.onTap, this.showSupplier = true});

  final Invoice invoice;
  final VoidCallback? onTap;
  final bool showSupplier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lavenderLight,
              child: Text(invoice.supplierName.substring(0, 1),
                  style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(invoice.number, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    if (invoice.isFlagged) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.gpp_maybe_outlined, size: 16, color: AppColors.amber),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    showSupplier ? invoice.supplierName : invoice.buyerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusPill(status: invoice.status),
                      Text('Due ${Fmt.date(invoice.dueDate)}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.money(invoice.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 6),
                Text(Fmt.relative(invoice.updatedAt), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.valueColor, this.bold = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: 13, color: valueColor ?? AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(children: [
        Icon(icon, size: 42, color: AppColors.lavender),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ]),
    );
  }
}

/// Small coloured note box (info / warning / success).
class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.icon, required this.color, required this.title, this.lines = const []});

  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $line', style: const TextStyle(color: AppColors.ink, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal progress bar with label and value, used for aging buckets.
class BarRow extends StatelessWidget {
  const BarRow({super.key, required this.label, required this.value, required this.fraction, this.color = AppColors.purple});

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.lavenderLight,
          ),
        ),
      ]),
    );
  }
}

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirmLabel = 'Confirm', bool destructive = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.red, minimumSize: const Size(0, 40)) : FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
