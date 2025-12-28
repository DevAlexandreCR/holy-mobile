import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:holyverso/core/router/app_router.dart';
import 'package:holyverso/main.dart';

void main() {
  testWidgets('boots app with injected router', (WidgetTester tester) async {
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _FakeHome(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
        ],
        child: const HolyVersoApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Home'), findsOneWidget);
  });
}

class _FakeHome extends StatelessWidget {
  const _FakeHome();

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(child: Text('Test Home')),
    );
  }
}
