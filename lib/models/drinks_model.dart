import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/rest_api.dart';
import 'drink.dart';

const kNoFilterString = 'No Filter';
const kAlcoholicString = 'Alcoholic';
const kNonAlcoholicString = 'Non Alcoholic';

//Preferisco una gestione client-side, non tutte le API hanno i dati completi
//e inoltre hanno un limite di 25.
class DrinksModel extends ChangeNotifier {
  ///Lista cocktails
  final List<Drink> _drinks = [];

  ///Lista cocktail filtrata
  List<Drink> _filteredDrinks = [];

  ///IDs cocktail preferiti
  List<int> _favorites = [];

  ///Lista categorie
  List<String> _categories = [];

  ///Filtro categoria
  String _categoryFilterBy = "No Filter";

  ///Filtro ingrediente
  String _ingredientFilterBy = "";

  ///Stato di caricamento
  bool _loading = true;

  ///Eventuale messaggio di errore;
  String? _error;

  ///Cocktail selezionato
  int? selectedDrinkId;

  List<Drink> get drinks => _filteredDrinks;
  List<int> get favorites => _favorites;
  List<String> get categories => _categories;

  String get categoryFilterBy => _categoryFilterBy;
  String get ingredientFilterBy => _ingredientFilterBy;

  bool get loading => _loading;
  String? get error => _error;

  ///Con le API di test il massimo numero di elementi caricabile è 25.
  ///Per avere un elenco pià realistico carico i primi 25 per ogni lettera dell'alfabeto
  Future getDrinks() async {
    try {
      _error = null;
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

      //Carico gli id dei preferiti precedentemente salvati
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey('favorites')) {
        _favorites = jsonDecode(prefs.getString('favorites')!).cast<int>();
      }
    } on SocketException catch (_) {
      //Errore connessione
      _error = 'Server error. Please check your network connection.';
    } catch (e) {
      //Errore generico
      _error = "An unexpected error has occurred. Please try again later.";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ///Simulazione caricamento dati
  Future getMockDrinks(bool throwException) async {
    try {
      if (throwException) {
        throw "test exception";
      }

      for (int i = 0; i < 10; i++) {
        _drinks.add(Drink(
            id: i,
            name: 'DRINK $i',
            thumb: "",
            category: "CAT ${i.isEven ? 'CAT 1' : 'CAT 2'}",
            alcoholic: i.isEven,
            ingredients: []));
      }

      _filteredDrinks = List.from(_drinks);

      //Categorie
      _categories = ["CAT1", "CAT2"];

      //Carico gli id dei preferiti precedentemente salvati
      final prefs = await SharedPreferences.getInstance();

      if (prefs.containsKey('favorites')) {
        _favorites = jsonDecode(prefs.getString('favorites')!).cast<int>();
      }
    } catch (e) {
      //Può verificarsi un'eccezione in caso di connessione mancante o un errore del web service
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ///Filtra per categoria o per alcolico / non alcolico
  void filterByCategory(String category) {
    _categoryFilterBy = category;
    _ingredientFilterBy = "";

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

  ///Recupero lista dei preferiti
  List<Drink> getFavorites() {
    final result = _drinks.where((e) => _favorites.contains(e.id)).toList();

    return result;
  }

  ///Ricerca cocktails
  List<Drink> search(String query) {
    final q = query.toLowerCase();

    final result = _drinks
        .where((e) => searchByName(e, q) || searchByIngredient(e, q))
        .toList();

    return result;
  }

  ///Ricerca per nome
  bool searchByName(Drink cocktail, String query) {
    return cocktail.name.toLowerCase().contains(query);
  }

  ///Ricerca per ingrediente
  bool searchByIngredient(Drink cocktail, String query) {
    return cocktail.ingredients
        .any((e) => e.name.toLowerCase().contains(query));
  }

  ///Aggiunge l'id del cocktail ai preferiti
  Future addFavorite(int drinkId) async {
    _favorites.add(drinkId);
    await _writeFavorites();
    notifyListeners();
  }

  ///Rimuove l'id del cocktail dai preferiti
  Future removeFavorite(int drinkId) async {
    _favorites.remove(drinkId);
    _writeFavorites();
    notifyListeners();
  }

  ///Salva i preferiti in modo da essere recuperati successivamente
  Future _writeFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('favorites', jsonEncode(_favorites));
  }

  /// Dettagli per tablet
  void showDetails(int drinkId) {
    selectedDrinkId = drinkId;
    notifyListeners();
  }
}
