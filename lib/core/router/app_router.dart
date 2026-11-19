import 'package:go_router/go_router.dart';
import '../../data/models/event_model.dart';
import '../../features/event_detail/event_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/propose_event/propose_event_screen.dart';
import '../../features/static_pages/static_page_screen.dart';
import '../widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/propose', builder: (context, state) => const ProposeEventScreen()),
        ]),
      ],
    ),
    GoRoute(
      path: '/event',
      builder: (context, state) => EventDetailScreen(event: state.extra as EventModel),
    ),
    GoRoute(
      path: '/page/:slug',
      builder: (context, state) => StaticPageScreen(slug: state.pathParameters['slug']!),
    ),
  ],
);
