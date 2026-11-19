import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/main_shell.dart';

class _PageBlock {
  final String? heading;
  final String? paragraph;
  final List<String>? bullets;
  const _PageBlock({this.heading, this.paragraph, this.bullets});
}

class StaticPageScreen extends StatelessWidget {
  final String slug;

  const StaticPageScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final page = _pages[slug] ?? _pages['privacy']!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Я-Город', style: TextStyle(color: Color(0xFF2B3A67), fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(page.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...page.blocks.expand((b) => [
                if (b.heading != null) ...[
                  Text(b.heading!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                ],
                if (b.paragraph != null) ...[
                  Text(b.paragraph!, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 12),
                ],
                if (b.bullets != null) ...[
                  ...b.bullets!.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 14, height: 1.4))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
              ]),
          if (slug == 'contacts') ...[
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined, color: Color(0xFF2B3A67)),
              title: const Text('+7 (3496) 00-00-00'),
              onTap: () => launchUrl(Uri.parse('tel:+73496000000')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: Color(0xFF2B3A67)),
              title: const Text('info@yagorod.ru'),
              onTap: () => launchUrl(Uri.parse('mailto:info@yagorod.ru')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2B3A67)),
              title: const Text('Открыть канал в МАХ ↗'),
              onTap: () => launchUrl(Uri.parse('https://max.ru'), mode: LaunchMode.externalApplication),
            ),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: null,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/news');
          if (index == 2) context.go('/propose');
        },
      ),
    );
  }

  static const Map<String, ({String title, List<_PageBlock> blocks})> _pages = {
    'privacy': (
      title: 'Политика конфиденциальности',
      blocks: [
        _PageBlock(
          heading: '1. Общие положения',
          paragraph: 'Сервис «Я-Город» помогает жителям и гостям Ноябрьска знакомиться с актуальной афишей и новостями.',
        ),
        _PageBlock(
          heading: '2. Какие данные мы обрабатываем',
          bullets: [
            'Сведения о мероприятии, переданные через форму «Предложить мероприятие».',
            'ФИО и номер телефона контактного лица для связи редакции с организатором.',
          ],
        ),
      ],
    ),
    'personal-data': (
      title: 'Обработка персональных данных',
      blocks: [
        _PageBlock(
          paragraph: 'Персональные данные обрабатываются в соответствии с 152-ФЗ исключительно для проверки и публикации заявок.',
        ),
      ],
    ),
    'terms': (
      title: 'Условия использования',
      blocks: [
        _PageBlock(
          heading: 'Правила сервиса',
          bullets: [
            'Расписание и цены носят справочный характер — уточняйте детали у организаторов.',
            'Запрещено размещать материалы, нарушающие законодательство РФ.',
          ],
        ),
      ],
    ),
    'contacts': (
      title: 'Контакты',
      blocks: [
        _PageBlock(
          paragraph: 'Редакция городского портала «Я-Город» (г. Ноябрьск). По вопросам публикации мероприятий и партнёрства свяжитесь с нами:',
        ),
      ],
    ),
  };
}
