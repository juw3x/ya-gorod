import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/scroll_bus.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTabTap(int index) {
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
      ScrollBus.scrollTabToTop(index);
    } else {
      navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Text(
              'Я-Город',
              style: TextStyle(color: Color(0xFF2B3A67), fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: Colors.black12),
            const SizedBox(width: 10),
            const Text(
              'Ноябрьск',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: AppDrawer(
        onSelectTab: (index) {
          Navigator.pop(context);
          _onTabTap(index);
        },
        onSelectAfisha: () {
          Navigator.pop(context);
          navigationShell.goBranch(0, initialLocation: true);
          Future.delayed(const Duration(milliseconds: 120), ScrollBus.scrollToAfisha);
        },
      ),
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNoneSelected = currentIndex == null;
    return BottomNavigationBar(
      currentIndex: currentIndex ?? 0,
      onTap: onTap,
      backgroundColor: Colors.white,
      selectedItemColor: isNoneSelected ? Colors.grey : const Color(0xFF2B3A67),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Главная'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper), label: 'Новости'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Предложить'),
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  final VoidCallback onSelectAfisha;

  const AppDrawer({super.key, required this.onSelectTab, required this.onSelectAfisha});

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Меню', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Я-Город', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2B3A67))),
                  SizedBox(height: 2),
                  Text('Городские события и возможности', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            _sectionHeader('РАЗДЕЛЫ'),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Главная'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
              onTap: () => onSelectTab(0),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Афиша мероприятий'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
              onTap: onSelectAfisha,
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_outlined),
              title: const Text('Новости'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
              onTap: () => onSelectTab(1),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Предложить мероприятие'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
              onTap: () => onSelectTab(2),
            ),
            const Divider(),
            _sectionHeader('ИНФОРМАЦИЯ'),
            _docTile(context, 'Политика конфиденциальности', 'privacy'),
            _docTile(context, 'Политика обработки персональных данных', 'personal-data'),
            _docTile(context, 'Условия использования', 'terms'),
            const Divider(),
            _sectionHeader('КОНТАКТЫ'),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('+7 (3496) 00-00-00'),
              subtitle: const Text('Перейти в контакты'),
              onTap: () {
                Navigator.pop(context);
                context.push('/page/contacts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2B3A67)),
              title: const Text('Мы в МАХ'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => launchUrl(Uri.parse('https://max.ru'), mode: LaunchMode.externalApplication),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text('© 2026 Я-Город · Ноябрьск', style: TextStyle(fontSize: 12, color: Colors.black45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docTile(BuildContext context, String title, String slug) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
      onTap: () {
        Navigator.pop(context);
        context.push('/page/$slug');
      },
    );
  }
}
