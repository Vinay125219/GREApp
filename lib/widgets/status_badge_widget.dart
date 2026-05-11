import 'package:flutter/material.dart';

enum BadgeStatus {
  active,
  completed,
  pending,
  inProgress,
  overdue,
  scheduled,
  cancelled,
  graded,
  open,
  resolved,
  easy,
  medium,
  hard,
}

class StatusBadgeWidget extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.customLabel,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        customLabel ?? config.label,
        style: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: config.textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case BadgeStatus.active:
        return _BadgeConfig(
          'Active',
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
        );
      case BadgeStatus.completed:
        return _BadgeConfig(
          'Completed',
          const Color(0xFFDBE4FF),
          const Color(0xFF1E3A8A),
        );
      case BadgeStatus.pending:
        return _BadgeConfig(
          'Pending',
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
        );
      case BadgeStatus.inProgress:
        return _BadgeConfig(
          'In Progress',
          const Color(0xFFE0F2FE),
          const Color(0xFF0369A1),
        );
      case BadgeStatus.overdue:
        return _BadgeConfig(
          'Overdue',
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
        );
      case BadgeStatus.scheduled:
        return _BadgeConfig(
          'Scheduled',
          const Color(0xFFEDE9FE),
          const Color(0xFF5B21B6),
        );
      case BadgeStatus.cancelled:
        return _BadgeConfig(
          'Cancelled',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        );
      case BadgeStatus.graded:
        return _BadgeConfig(
          'Graded',
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
        );
      case BadgeStatus.open:
        return _BadgeConfig(
          'Open',
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
        );
      case BadgeStatus.resolved:
        return _BadgeConfig(
          'Resolved',
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
        );
      case BadgeStatus.easy:
        return _BadgeConfig(
          'Easy',
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
        );
      case BadgeStatus.medium:
        return _BadgeConfig(
          'Medium',
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
        );
      case BadgeStatus.hard:
        return _BadgeConfig(
          'Hard',
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  const _BadgeConfig(this.label, this.backgroundColor, this.textColor);
}
