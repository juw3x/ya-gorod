import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/scroll_bus.dart';

class YaLogoBadge extends StatelessWidget {
  final double size;
  const YaLogoBadge({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B3A67), Color(0xFF4A62A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        'Я',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.62,
          height: 1,
        ),
      ),
    );
  }
}

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
            const YaLogoBadge(size: 28),
            const SizedBox(width: 8),
            const Text(
              'Я-Город',
              style: TextStyle(color: Color(0xFF2B3A67), fontWeight: FontWeight.w800, fontSize: 19),
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
    final isNoneSelected = currentIndex == null || currentIndex! > 1;
    return BottomNavigationBar(
      currentIndex: isNoneSelected ? 0 : currentIndex!,
      onTap: onTap,
      backgroundColor: Colors.white,
      selectedItemColor: isNoneSelected ? Colors.grey : const Color(0xFF2B3A67),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Главная'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper), label: 'Новости'),
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
              child: Row(
                children: [
                  YaLogoBadge(size: 36),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Я-Город', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2B3A67))),
                      Text('Городские события и новости', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
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
              title: const Text('Афиша города'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
              onTap: onSelectAfisha,
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_outlined),
              title: const Text('Новости'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
              onTap: () => onSelectTab(1),
            ),
            const Divider(),
            _sectionHeader('ИНФОРМАЦИЯ'),
            _docTile(context, 'Политика конфиденциальности', 'privacy'),
            _docTile(context, 'Политика обработки персональных данных', 'personal-data'),
            _docTile(context, 'Условия использования', 'terms'),
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
