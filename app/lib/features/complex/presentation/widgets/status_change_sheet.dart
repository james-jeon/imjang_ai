import 'package:flutter/material.dart';
import 'package:imjang_app/features/complex/domain/entities/complex_status.dart';

class StatusChangeSheet extends StatelessWidget {
  final ComplexStatus currentStatus;
  final ValueChanged<ComplexStatus> onStatusSelected;

  const StatusChangeSheet({
    super.key,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ComplexStatus.values
          .map(
            (s) => ListTile(
              key: Key('status_option_${s.name}'),
              title: Text(s.label),
              selected: s == currentStatus,
              onTap: () {
                onStatusSelected(s);
                Navigator.pop(context);
              },
            ),
          )
          .toList(),
    );
  }

  static void show(
    BuildContext context, {
    required ComplexStatus currentStatus,
    required ValueChanged<ComplexStatus> onStatusSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatusChangeSheet(
        currentStatus: currentStatus,
        onStatusSelected: onStatusSelected,
      ),
    );
  }
}
