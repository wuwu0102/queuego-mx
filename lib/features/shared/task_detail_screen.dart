import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/task_item.dart';
import '../../data/fake_data.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final updates = fakeUpdates.where((u) => u.taskId == task.taskId).toList();
    final lower = '${task.title} ${task.placeName}'.toLowerCase();
    final isSensitive = lower.contains('sat') ||
        lower.contains('gobierno') ||
        lower.contains('hospital') ||
        lower.contains('imss');
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(task.description),
          const SizedBox(height: 12),
          Text('Runner: ${task.runnerId ?? 'Sin asignar'}'),
          Text('Posición en fila: ${updates.isNotEmpty ? updates.last.queuePosition ?? '-' : '-'}'),
          Text('Tiempo restante estimado: ${updates.isNotEmpty ? updates.last.estimatedRemainingMinutes ?? '-' : '-'} min'),
          const SizedBox(height: 10),
          Text(
            s.t('globalComplianceNoticeEs'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (isSensitive) ...[
            const SizedBox(height: 4),
            Text(
              s.t('institutionRiskNoticeEs'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Divider(height: 28),
          const Text('Línea de tiempo', style: TextStyle(fontWeight: FontWeight.bold)),
          ...updates.map(
            (u) => Card(
              child: ListTile(
                title: Text('${u.type}: ${u.message}'),
                subtitle: Text(u.createdAt.toString()),
                trailing: u.photoUrl != null ? const Icon(Icons.image) : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Confirmar finalización')),
              OutlinedButton(onPressed: () {}, child: const Text('Cancelar tarea')),
              OutlinedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Reporte / Disputa'),
                    content: const Text('Espacio temporal para reportes/disputas y revisión administrativa.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                ),
                child: const Text('Reportar problema'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
