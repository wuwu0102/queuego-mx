import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final sections = _termsSections(s.locale);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('termsTitle'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              for (final section in sections) ...[
                _TermsSectionCard(section: section),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_TermsSection> _termsSections(Locale locale) {
    if (locale.languageCode == 'en') {
      return const [
        _TermsSection(
          title: '1) What QueueGo MX is',
          paragraphs: [
            'QueueGo MX is a matching platform connecting people who need support with lines or short waiting times and people available to provide in-person support.',
          ],
        ),
        _TermsSection(
          title: '2) We are not an institution',
          paragraphs: [
            'QueueGo MX does not provide legal, medical, financial, government, or official representation services.',
          ],
        ),
        _TermsSection(
          title: '3) We do not guarantee results',
          paragraphs: [
            'QueueGo MX does not guarantee results, turns, approvals, or preferential attention.',
          ],
        ),
        _TermsSection(
          title: '4) User responsibility',
          paragraphs: [
            'Each user must verify whether the location allows third-party support.',
          ],
        ),
        _TermsSection(
          title: '5) Prohibited activities',
          bullets: [
            'Impersonating identity',
            'Selling turns when prohibited',
            'Skipping lines',
            'Manipulating appointment systems',
            'Illegal or fraudulent activities',
          ],
        ),
        _TermsSection(
          title: '6) What a runner may do',
          bullets: [
            'Wait in line',
            'Hold a place when allowed',
            'Send updates',
            'Notify when the turn is near',
            'Coordinate handoff',
          ],
        ),
        _TermsSection(
          title: '7) Payments',
          paragraphs: [
            'Price and payment are agreed directly between users.',
            'QueueGo MX does not process payments or retain money.',
          ],
        ),
      ];
    }
    return const [
      _TermsSection(
        title: '1️⃣ Qué es QueueGo MX',
        paragraphs: [
          'QueueGo MX es una plataforma piloto que conecta personas que necesitan apoyo en filas o esperas cortas con personas disponibles para brindar apoyo presencial.',
        ],
      ),
      _TermsSection(
        title: '2️⃣ No somos una institución',
        paragraphs: [
          'QueueGo MX no ofrece servicios de representación legal, médica, financiera, gubernamental ni oficial.',
        ],
      ),
      _TermsSection(
        title: '3️⃣ No garantizamos resultados',
        paragraphs: [
          'QueueGo MX no garantiza resultados, turnos, aprobaciones ni atención preferente.',
        ],
      ),
      _TermsSection(
        title: '4️⃣ Responsabilidad del usuario',
        paragraphs: [
          'Cada usuario debe verificar si el lugar permite apoyo de terceros.',
        ],
      ),
      _TermsSection(
        title: '5️⃣ Actividades prohibidas',
        bullets: [
          'Suplantar identidad',
          'Vender turnos cuando esté prohibido',
          'Saltarse filas',
          'Manipular sistemas de citas',
          'Actividades ilegales o fraudulentas',
        ],
      ),
      _TermsSection(
        title: '6️⃣ Qué puede hacer el runner',
        bullets: [
          'Esperar en fila',
          'Guardar lugar si es permitido',
          'Enviar actualizaciones',
          'Avisar cuando falte poco',
          'Coordinar entrega',
        ],
      ),
      _TermsSection(
        title: '7️⃣ Pagos',
        paragraphs: [
          'El precio y pago se acuerdan entre usuarios.',
          'QueueGo MX no procesa pagos ni retiene dinero.',
        ],
      ),
    ];
  }
}

class _TermsSection {
  const _TermsSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

class _TermsSectionCard extends StatelessWidget {
  const _TermsSectionCard({required this.section});

  final _TermsSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                style: const TextStyle(height: 1.7),
              ),
            ),
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '• $bullet',
                style: const TextStyle(height: 1.7),
              ),
            ),
        ],
      ),
    );
  }
}
