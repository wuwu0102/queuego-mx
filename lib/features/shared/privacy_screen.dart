import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bullets = _privacyBullets(s.locale);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('privacyTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('privacyTitle'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  List<String> _privacyBullets(Locale locale) {
    if (locale.languageCode == 'en') {
      return const [
        'QueueGo MX may collect information needed to operate the service, including email, visible name or user identifier, task information, user-written location, task messages/updates, ratings/comments, and basic technical session data.',
        'We use this information to publish tasks, request/accept tasks, show task status, coordinate in-platform communication, prevent abuse/fraud/misuse, manage ratings and trust, and improve service security.',
        'QueueGo MX does not sell personal data.',
        'QueueGo MX does not request sensitive documents or sensitive personal information unless strictly necessary.',
        'Users should not share sensitive data within the platform.',
        'Information may be stored in third-party services used by the platform, such as Firebase / Google Cloud.',
        'Users may request review or deletion of information by contacting the service administrator.',
      ];
    }
    return const [
      'QueueGo MX puede recopilar información necesaria para operar el servicio, incluyendo: correo electrónico; nombre visible o identificador de usuario; información de tareas publicadas; ubicación escrita por el usuario; mensajes o actualizaciones relacionados con tareas; calificaciones y comentarios; datos técnicos básicos necesarios para iniciar sesión y mantener la sesión.',
      'Usamos esta información para: permitir publicar tareas; permitir solicitar o aceptar tareas; mostrar el estado de una tarea; coordinar comunicación dentro de la plataforma; prevenir abuso, fraude o mal uso; administrar calificaciones y confianza; mejorar la seguridad del servicio.',
      'QueueGo MX no vende datos personales.',
      'QueueGo MX no solicita información sensible ni datos personales delicados salvo cuando sea estrictamente necesario.',
      'Los usuarios no deben compartir datos sensibles dentro de la plataforma.',
      'La información puede almacenarse en servicios de terceros usados por la plataforma, como Firebase / Google Cloud.',
      'El usuario puede solicitar revisión o eliminación de información escribiendo al administrador del servicio.',
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
        const Text('• '),
        Expanded(child: Text(text)),
      ],
    );
  }
}
