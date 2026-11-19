import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StaticPageScreen extends StatelessWidget {
  final String slug;

  const StaticPageScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final content = _pages[slug] ?? _pages['privacy']!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Информация', style: TextStyle(color: Colors.black87, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(content.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(content.body, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
          if (slug == 'contacts') ...[
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('+7 (000) 000-00-00'),
              onTap: () => launchUrl(Uri.parse('tel:+70000000000')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text('info@yagorod.ru'),
              onTap: () => launchUrl(Uri.parse('mailto:info@yagorod.ru')),
            ),
          ],
        ],
      ),
    );
  }

  static const Map<String, ({String title, String body})> _pages = {
    'privacy': (
      title: 'Политика конфиденциальности',
      body: 'Сервис «Я-Город» помогает знакомиться с городской афишей и новостями Ноябрьска.\n\n'
          '1. Общая информация\nМы обрабатываем только те сведения, которые пользователь добровольно передает при отправке заявки на публикацию мероприятия.',
    ),
    'personal-data': (
      title: 'Политика обработки персональных данных',
      body: 'Контактные данные (ФИО и номер телефона) используются исключительно для связи редакции с организатором мероприятия для уточнения деталей.',
    ),
    'terms': (
      title: 'Условия использования',
      body: 'Информация о расписании и стоимости мероприятий носит справочный характер. Актуальные условия входа уточняйте у организаторов.',
    ),
    'contacts': (
      title: 'Контакты',
      body: 'Редакция городского портала «Я-Город» (г. Ноябрьск). Свяжитесь с нами по телефону или электронной почте:',
    ),
  };
}
