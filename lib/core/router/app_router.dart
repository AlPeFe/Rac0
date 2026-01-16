import 'package:go_router/go_router.dart';
import '../../shared/layouts/main_layout.dart';
import '../../features/visited/view/visited_view.dart';
import '../../features/home/view/home_view.dart';
import '../../features/item/view/create_restaurant_view.dart';
import '../../features/item/view/restaurant_detail_view.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeView(),
          ),
          GoRoute(
            path: '/visited',
            name: 'visited',
            builder: (context, state) {
              return const VisitedView();
            },
          ),
          GoRoute(
            path: '/create',
            name: 'create',
            builder: (context, state) => const CreateRestaurantView(),
          ),
          GoRoute(
            path: '/restaurant/:id',
            name: 'restaurant-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RestaurantDetailView(restaurantId: id);
            },
          ),
        ],
      ),
    ],
  );
}