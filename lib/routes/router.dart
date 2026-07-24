import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/driver_trips/presentation/pages/my_trips_page.dart';
import '../features/driver_trips/presentation/pages/trip_detail_page.dart';

const String kLoginRoute = '/login';
const String kMyTripsRoute = '/my-trips';
const String kTripDetailRoute = '/trips/:tripId';

final routerProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: kLoginRoute,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == kLoginRoute;

      if (!authSession.isLoggedIn) {
        return isLoggingIn ? null : kLoginRoute;
      }

      if (!authSession.isDriver) {
        // Logged in but not a driver — stay on login to show error
        return kLoginRoute;
      }

      if (isLoggingIn) {
        return kMyTripsRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: kLoginRoute,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: kMyTripsRoute,
        builder: (context, state) => const MyTripsPage(),
      ),
      GoRoute(
        path: kTripDetailRoute,
        builder: (context, state) {
          final tripId = int.parse(state.pathParameters['tripId']!);
          return TripDetailPage(tripId: tripId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Trang không tìm thấy',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(kMyTripsRoute),
              child: const Text('Về trang chính'),
            ),
          ],
        ),
      ),
    ),
  );
});
