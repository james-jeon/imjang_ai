import 'package:flutter/material.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

class StatusBadge extends StatelessWidget {
  final ComplexStatus status;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.status,
    this.onTap,
  });

  Color _statusColor() {
    switch (status) {
      case ComplexStatus.interested:
        return Colors.blue;
      case ComplexStatus.planned:
        return Colors.orange;
      case ComplexStatus.visited:
        return Colors.green;
      case ComplexStatus.revisit:
        return Colors.purple;
      case ComplexStatus.excluded:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }
    return badge;
  }
}
