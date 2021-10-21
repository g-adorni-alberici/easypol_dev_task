import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/drink.dart';

//Versione free limitata a 25 per la ricerca e 100 per gli elenchi
class RestApi {
  static const domain = 'www.thecocktaildb.com';

  ///Funzione generale con pattern standard per richiamare una GET
  static dynamic get(String task, [Map<String, dynamic>? parameters]) async {
    if (parameters != null) {
      parameters =
          parameters.map((key, value) => MapEntry(key, value?.toString()));
    }

    final url = Uri.https(domain, 'api/json/v1/1/$task.php', parameters);

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(response.reasonPhrase);
    }

    final json = jsonDecode(response.body);

    return json;
  }

  ///Ricerca cocktail per nome
  static Future<List<Drink>> searchCocktailByName(String query) async {
    final json = await get('search', {'s': query});

    final drinks = json['drinks'].map<Drink>((e) => Drink.fromJson(e)).toList();

    return drinks;
  }

  ///Ricerca cocktails per lettera
  static Future<List<Drink>> listCocktailsByLetter(String letter) async {
    final json = await get('search', {'f': letter});

    if (json['drinks'] == null) return [];

    return json['drinks'].map<Drink>((e) => Drink.fromJson(e)).toList();
  }

  ///Elenco categorie
  static Future<List<String>> listCategories() async {
    //Prendo tutti
    final json = await get('list', {'c': 'list'});

    final drinks =
        json['drinks'].map<String>((e) => '${e['strCategory']}').toList();

    return drinks;
  }

  ///Elenco ingredienti
  static Future<List<String>> listIngredients() async {
    final json = await get('list', {'i': 'list'});

    final drinks =
        json['drinks'].map<String>((e) => '${e['strIngredient1']}').toList();

    return drinks;
  }

  ///Dettaglio Cocktail
  static Future<Drink> lookupCocktailDetail(int id) async {
    final json = await get('lookup', {'i': id});

    final drinks = json['drinks'].map<Drink>((e) => Drink.fromJson(e)).toList();

    return drinks[0];
  }
}
