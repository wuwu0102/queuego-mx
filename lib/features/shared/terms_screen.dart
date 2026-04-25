import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Términos de uso – QueueGo MX',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _CheckItem(
              text:
                  'Esta plataforma solo conecta personas para asistencia en filas.',
            ),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'No garantizamos resultados con ninguna institución (gobierno, bancos, hospitales, escuelas o empresas privadas).',
            ),
            SizedBox(height: 10),
            _CheckItem(text: 'Está prohibido:'),
            _BulletItem(text: 'Revender turnos'),
            _BulletItem(text: 'Suplantar identidad'),
            _BulletItem(text: 'Manipular sistemas de fila'),
            _BulletItem(text: 'Cualquier actividad ilegal'),
            SizedBox(height: 10),
            _CheckItem(text: 'La persona asistente solo proporciona:'),
            _BulletItem(text: 'Esperar en fila'),
            _BulletItem(text: 'Actualizaciones en tiempo real'),
            _BulletItem(text: 'Evidencia básica (foto o mensaje)'),
            SizedBox(height: 10),
            _CheckItem(text: 'Si el lugar prohíbe terceros en fila:'),
            Padding(
              padding: EdgeInsets.only(left: 28),
              child: Text('→ la persona asistente debe informar inmediatamente'),
            ),
            SizedBox(height: 10),
            _CheckItem(text: 'El pago y acuerdo son responsabilidad de ambas partes'),
            SizedBox(height: 10),
            _CheckItem(text: 'Para mayor seguridad:'),
            _BulletItem(text: 'Se utilizará un código de verificación'),
            _BulletItem(text: 'Ambas partes deben confirmar antes de finalizar'),
            SizedBox(height: 10),
            _CheckItem(text: 'Después de completar:'),
            _BulletItem(text: 'Ambas partes pueden calificarse mutuamente'),
            SizedBox(height: 10),
            _CheckItem(
              text:
                  'La plataforma puede suspender cuentas por comportamiento sospechoso',
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

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 2),
      child: Text('* $text'),
    );
  }
}
