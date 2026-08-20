import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SfaSectionTitle extends StatelessWidget {
  const SfaSectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      );
}

class SfaStatusChip extends StatelessWidget {
  const SfaStatusChip({super.key, required this.label, this.color = AppColors.success});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(7)),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

class SfaIconTile extends StatelessWidget {
  const SfaIconTile({super.key, required this.icon, required this.label, required this.color, this.badge, this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    if (badge != null)
                      Positioned(
                        top: -5,
                        right: -7,
                        child: CircleAvatar(radius: 8, backgroundColor: AppColors.danger, child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9))),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

class SfaEmptyState extends StatelessWidget {
  const SfaEmptyState({super.key, required this.icon, required this.title, required this.description, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 34, backgroundColor: AppColors.primarySoft, child: Icon(icon, size: 34, color: AppColors.primary)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), if (actionLabel != null) ...[const SizedBox(height: 16), OutlinedButton(onPressed: onAction, child: Text(actionLabel!))]])));
}
