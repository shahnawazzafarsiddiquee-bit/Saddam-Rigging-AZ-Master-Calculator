import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/calculation_engine.dart';

/// Reuses the established palette and typography. Status describes the entered
/// numerical check, never permission to conduct a lift.
class CalculationDetails extends StatelessWidget {
  final CalculationResult result;
  const CalculationDetails({super.key, required this.result});
  @override
  Widget build(BuildContext context) {
    final color = switch (result.status) {
      CheckStatus.acceptable => AppColors.success,
      CheckStatus.notAcceptable => AppColors.danger,
      _ => AppColors.warning,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            result.statusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        ExpansionTile(
          title: const Text('Method, sources & assumptions'),
          children: [
            ListTile(
              title: Text(result.method),
              subtitle: Text('Source: ${result.source}'),
            ),
            for (final input in result.inputs.entries)
              ListTile(
                dense: true,
                title: Text(input.key),
                trailing: Text(
                  '${input.value} ${result.units[input.key] ?? ''}',
                ),
              ),
            for (final assumption in result.assumptions)
              ListTile(dense: true, title: Text(assumption)),
          ],
        ),
        for (final warning in result.warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              warning,
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        const Text(
          'Decision support only. Final lifting authorization remains with authorized personnel.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
