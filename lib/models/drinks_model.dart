import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/rest_api.dart';
import 'drink.dart';

const kNoFilterString = 'No Filter';
const kAlcoholicString = 'Alcoholic';
const kNonAlcoholicString = 'Non Alcoholic';

//Preferisco una gestione client-side, non tutte le API hanno i dati completi
//e inoltre hanno un limite di 25.
class DrinksModel extends ChangeNotifier {
  DrinksModel() {
    getDrinks();
  }
  //Lista cocktails
  final List<Drink> _drinks = [];
  //Lista cocktail filtrata
  List<Drink> _filteredDrinks = [];

  //IDs cocktail preferiti
  final List<int> _favorites = [];

  //Lista categorie
  List<String> _categories = [];

  //Filtro categoria
  String _categoryFilterBy = "No Filter";
  //Filtro ingrediente
  String _ingredientFilterBy = "";

  //Stato di caricamento
  bool _loading = true;

  //Eventuale messaggio di errore;
  String? _error;

  List<Drink> get drinks => _filteredDrinks;
  List<int> get favorites => _favorites;
  List<String> get categories => _categories;

  String get categoryFilterBy => _categoryFilterBy;
  String get ingredientFilterBy => _ingredientFilterBy;

  bool get loading => _loading;
  String? get error => _error;

  ///Con l'API di test il massimo numero di elementi caricabili è 25.
  ///Per avere un elenco pià realistico carico i primi 25 per ogni lettera dell'alfabeto
  Future getDrinks() async {
    try {
      //Preparo i futures che saranno caricati contemporaneamente
      var futures = <Future>[];
      for (int i = 'A'.codeUnitAt(0); i <= 'Z'.codeUnitAt(0); i++) {
        futures.add(RestApi.listCocktailsByLetter(String.fromCharCode(i)));
      }

      //Categorie per i filtri
      futures.add(RestApi.listCategories());

      //Caricamento complessivo
      final responses = await Future.wait(futures);

      //Popolazione liste cocktails
      for (List<Drink> response in responses.take(responses.length - 1)) {
        _drinks.addAll(response);
      }

      _filteredDrinks = List.from(_drinks);

      //Categorie
      _categories = responses.last as List<String>;

      //Fine caricamento
      _loading = false;
    } catch (e) {
      //Può verificarsi un'eccezione in caso di connessione mancante o un errore del web service
      _error = 'Server error. Check connection';
    } finally {
      notifyListeners();
    }
  }

  //Filtra per categoria
  void filterByCategory(String category) {
    _categoryFilterBy = category;

    if (category == kNoFilterString) {
      //Ripristino la lista completa
      _filteredDrinks = List.from(_drinks);
    } else if (category == kAlcoholicString) {
      //Cocktail alcolici
      _filteredDrinks = _drinks.where((e) => e.alcoholic).toList();
    } else if (category == kNonAlcoholicString) {
      //Cocktail non alcolici
      _filteredDrinks = _drinks.where((e) => !e.alcoholic).toList();
    } else {
      //In base alla categoria selezionata
      _filteredDrinks = _drinks.where((e) => e.category == category).toList();
    }

    notifyListeners();
  }

  //Filtra per ingrediente
  void filterByIngredient(String ingredient) {
    _ingredientFilterBy = ingredient;
    _categoryFilterBy = kNoFilterString;

    _filteredDrinks = _drinks
        .where((e) => e.ingredients.any((i) => i.name == ingredient))
        .toList();

    notifyListeners();
  }

  //Ricerca cocktails
  List<Drink> getFavorites() {
    final result = _drinks.where((e) => _favorites.contains(e.id)).toList();

    return result;
  }

  //Ricerca cocktails
  List<Drink> search(String query) {
    final q = query.toLowerCase();

    final result = _drinks
        .where((e) => searchByName(e, q) || searchByIngredient(e, q))
        .toList();

    return result;
  }

  //Ricerca per nome
  bool searchByName(Drink cocktail, String query) {
    return cocktail.name.toLowerCase().contains(query);
  }

  //Ricerca per ingrediente
  bool searchByIngredient(Drink cocktail, String query) {
    return cocktail.ingredients
        .any((e) => e.name.toLowerCase().contains(query));
  }

  //Aggiunge l'id del cocktail ai preferiti
  void addFavorite(int drinkId) {
    _favorites.add(drinkId);
    notifyListeners();
  }

  //Rimuove l'id del cocktail dai preferiti
  void removeFavorite(int _drinkId) {
    _favorites.remove(_drinkId);
    notifyListeners();
  }
}
