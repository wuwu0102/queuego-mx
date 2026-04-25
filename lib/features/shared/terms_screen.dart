import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos de uso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Términos de uso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _CheckItem(
              text:
                  'QueueGo MX conecta personas que necesitan apoyo en filas, trámites o esperas con personas disponibles para ayudar.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'QueueGo MX no representa ni garantiza resultados ante instituciones públicas, privadas, bancos, hospitales, escuelas o empresas.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'Cada usuario es responsable de revisar si el lugar permite apoyo de terceros en la fila.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'Está prohibido suplantar identidad, vender turnos oficiales, manipular sistemas de fila o realizar actividades ilegales.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'El runner puede apoyar esperando en fila, enviando actualizaciones, fotos de evidencia y avisos de avance.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'El pago, precio final y condiciones del servicio deben ser acordados entre las partes.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'Para mayor seguridad, se puede usar un código de verificación al momento de la entrega.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'Ambas partes pueden calificarse después de completar una tarea.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'QueueGo MX puede revisar, ocultar o cancelar tareas sospechosas o que incumplan estas reglas.',
            ),
          ],
        ),
      ),
    );
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
