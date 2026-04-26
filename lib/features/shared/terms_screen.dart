import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bullets = _termsBullets(s.locale);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('termsTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('termsTitle'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final line in bullets) ...[
              _CheckItem(text: line),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _termsBullets(Locale locale) {
    if (locale.languageCode == 'en') {
      return const [
        'QueueGo MX is a connection platform between people who need support in lines, procedures, or waiting times and people available to provide in-person support.',
        'QueueGo MX does not represent any public or private institution, bank, hospital, school, company, or authority.',
        'QueueGo MX does not guarantee results, turns, approvals, preferential attention, or completion of procedures.',
        'Each user is responsible for verifying whether the location allows a third party to wait in line, accompany, or provide in-person support.',
        'It is prohibited to impersonate identity, buy or sell official turns when forbidden, skip lines, alter local rules, manipulate appointment systems, perform procedures without valid authorization, or use the platform for illegal, deceptive, or fraudulent activities.',
        'Runners may only provide permitted support such as waiting in line, holding a place when allowed, sending updates, notifying when the turn is near, sharing progress evidence when possible, and coordinating in-person handoff with the customer.',
        'Price, payment method, service conditions, and any negotiation are agreed directly between the customer and runner.',
        'QueueGo MX currently does not process payments, hold money, charge commissions, or act as a financial intermediary.',
        'For additional safety, both parties may use a verification code during handoff.',
        'Both parties may rate each other after completing a task.',
        'QueueGo MX may review, hide, cancel, or remove suspicious, illegal, deceptive tasks, or tasks that violate these rules.',
        'Using QueueGo MX implies acceptance of these terms.',
      ];
    }
    return const [
      'QueueGo MX es una plataforma de conexión entre personas que necesitan apoyo en filas, trámites o esperas y personas disponibles para brindar apoyo presencial.',
      'QueueGo MX no representa a ninguna institución pública, privada, banco, hospital, escuela, empresa ni autoridad.',
      'QueueGo MX no garantiza resultados, turnos, aprobaciones, atención preferente ni resolución de trámites.',
      'Cada usuario es responsable de verificar si el lugar permite que un tercero espere en fila, acompañe o brinde apoyo presencial.',
      'Está prohibido: suplantar identidad; comprar, vender o transferir turnos oficiales cuando esté prohibido; saltarse filas o alterar reglas del lugar; manipular sistemas de citas, turnos o atención; realizar trámites en nombre de otra persona sin autorización válida; usar la plataforma para actividades ilegales, engañosas o fraudulentas.',
      'El runner solo puede brindar apoyo permitido, como: esperar en fila; guardar lugar cuando sea permitido; enviar actualizaciones; avisar cuando falte poco para el turno; compartir evidencia del avance cuando sea posible; coordinar la entrega presencial con el customer.',
      'El precio, forma de pago, condiciones del servicio y cualquier negociación son acordados directamente entre customer y runner.',
      'QueueGo MX actualmente no procesa pagos, no retiene dinero, no cobra comisiones y no actúa como intermediario financiero.',
      'Para mayor seguridad, ambas partes pueden usar un código de verificación al momento de la entrega.',
      'Ambas partes pueden calificarse después de completar una tarea.',
      'QueueGo MX puede revisar, ocultar, cancelar o eliminar tareas sospechosas, ilegales, engañosas o que incumplan estas reglas.',
      'Usar QueueGo MX implica aceptar estos términos.',
    ];
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('✔ '),
        Expanded(child: Text(text)),
      ],
    );
  }
}
