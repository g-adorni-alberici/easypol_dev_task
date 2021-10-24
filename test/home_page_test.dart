import 'package:dev_task_adorni/models/drinks_model.dart';
import 'package:dev_task_adorni/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> createHomeScreen() async {
  final model = DrinksModel();

  SharedPreferences.setMockInitialValues({});

  await model.getMockDrinks(false);

  return ChangeNotifierProvider<DrinksModel>(
    create: (context) => model,
    child: const MaterialApp(home: HomePage()),
  );
}

void main() {
  group('Home Page Tests', () {
    testWidgets('Test lista', (tester) async {
      final widget = await createHomeScreen();
      await tester.pumpWidget(widget);

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Test Scroll', (tester) async {
      final widget = await createHomeScreen();
      await tester.pumpWidget(widget);

      // Check if "Item 0" is present on the screen.
      expect(find.text('DRINK 0'), findsOneWidget);

      // Fling i.e scroll down.
      await tester.fling(find.byType(ListView), const Offset(0, -200), 3000);
      await tester.pumpAndSettle();

      // Check if "Item 0" disappeared.
      expect(find.text('DRINK 0'), findsNothing);
    });

    testWidgets('Testing IconButtons', (tester) async {
      final widget = await createHomeScreen();
      await tester.pumpWidget(widget);

      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Added to favorites.'), findsOneWidget);

      expect(find.byIcon(Icons.favorite), findsWidgets);

      await tester.tap(find.byIcon(Icons.favorite).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Removed from favorites.'), findsOneWidget);

      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });
}
