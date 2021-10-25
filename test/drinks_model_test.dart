import 'package:dev_task_adorni/models/drinks_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Drinks Model Test', () {
    DrinksModel model = DrinksModel();
    setUp(() {
      model = DrinksModel();
    });
    testWidgets('Caricamento dati', (tester) async {
      SharedPreferences.setMockInitialValues({'favorites': "[1,2]"});

      expect(model.loading, true);

      await model.getMockDrinks(false);

      expect(model.loading, false);
      expect(model.drinks.length, 10);
      expect(model.categories.length, 2);
      expect(model.favorites, [1, 2]);
      expect(model.error, null);
    });

    testWidgets('Caricamento dati con eccezione', (tester) async {
      expect(model.loading, true);

      await model.getMockDrinks(true);

      expect(model.loading, false);
      expect(model.error, "test exception");
    });

    testWidgets('Test aggiungi/rimuovi preferiti', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await model.getMockDrinks(false);

      await model.addFavorite(1);
      await model.addFavorite(2);

      final prefs = await SharedPreferences.getInstance();

      final json1 = prefs.getString('favorites');

      expect(json1, "[1,2]");

      await model.removeFavorite(1);

      final json2 = prefs.getString('favorites');
      expect(json2, "[2]");
    });
  });
}
