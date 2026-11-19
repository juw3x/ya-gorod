import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3A67),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Я',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ноябрьск',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const _AppMenuDrawer(),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: const Color(0xFF2B3A67),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), activeIcon: Icon(Icons.article), label: 'Новости'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Предложить'),
        ],
      ),
    );
  }
}

class _AppMenuDrawer extends StatelessWidget {
  const _AppMenuDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Меню', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('РАЗДЕЛЫ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Главная'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Новости'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/news');
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Предложить мероприятие'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/propose');
                    },
                  ),
                  const Divider(height: 32),
                  const Text('ИНФОРМАЦИЯ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Политика конфиденциальности'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/page/privacy');
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Политика обработки персональных данных'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/page/personal-data');
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Условия использования'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/page/terms');
                    },
                  ),
                  const Divider(height: 32),
                  const Text('КОНТАКТЫ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('+7 (000) 000-00-00'),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/page/contacts');
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('© 2026 Я-Город', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
