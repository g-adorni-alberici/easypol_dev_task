class Drink {
  Drink({
    required this.id,
    required this.name,
    required this.thumb,
    required this.category,
    required this.alcoholic,
    required this.ingredients,
    this.instructions,
  });

  final int id;
  final String name;
  final String thumb;
  final String category;
  final bool alcoholic;
  final String? instructions;
  final List<Ingredient> ingredients;

  //Immagine più piccola
  String get preview => thumb + '/preview';

  factory Drink.fromJson(Map<String, dynamic> json) {
    //Lista di ingredienti (max 15)
    final List<Ingredient> ingredients = [];

    for (int i = 1; i <= 15; i++) {
      if (json['strIngredient$i'] != null) {
        ingredients.add(Ingredient(
          name: json['strIngredient$i'],
          measure: json['strMeasure$i'],
        ));
      }
    }

    return Drink(
      id: int.parse(json['idDrink']),
      name: json['strDrink'],
      category: json['strCategory'],
      alcoholic: json['strAlcoholic'] == 'Alcoholic',
      thumb: json['strDrinkThumb'],
      ingredients: ingredients,
      instructions: json['strInstructions'],
    );
  }
}

class Ingredient {
  Ingredient({required this.name, this.measure});

  final String name;
  final String? measure;
}
