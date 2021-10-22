import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drink.dart';
import '../models/drinks_model.dart';
import 'drink_detail.dart';
import 'qr_scan.dart';

class HomePage extends StatelessWidget {
  static String routeName = '/home';

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<DrinksModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Easypol Cocktails'),
          actions: <Widget>[
            IconButton(
              onPressed: model.loading
                  ? null
                  : () => showSearch(
                        context: context,
                        delegate: DrinksSearchDelegate(model),
                      ),
              icon: const Icon(Icons.search),
            ),
            PopupMenuButton(
                enabled: !model.loading,
                onSelected: (result) => model.filterByCategory('$result'),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                      CheckedPopupMenuItem(
                        value: kNoFilterString,
                        checked: model.categoryFilterBy == kNoFilterString,
                        child: const Text(kNoFilterString),
                      ),
                      const PopupMenuDivider(),
                      CheckedPopupMenuItem(
                        value: kAlcoholicString,
                        checked: model.categoryFilterBy == kAlcoholicString,
                        child: const Text(kAlcoholicString),
                      ),
                      CheckedPopupMenuItem(
                        value: kNonAlcoholicString,
                        checked: model.categoryFilterBy == kNonAlcoholicString,
                        child: const Text(kNonAlcoholicString),
                      ),
                      const PopupMenuDivider(),
                      for (String c in model.categories)
                        CheckedPopupMenuItem(
                          checked: c == model.categoryFilterBy,
                          value: c,
                          child: Text(c),
                        )
                    ]),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text('COCKTAILS')),
              Tab(icon: Text('FAVORITES')),
            ],
          ),
        ),
        body: Builder(builder: (context) {
          if (model.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(children: [
            DrinksListView(drinks: model.drinks),
            DrinksListView(drinks: model.getFavorites()),
            // FutureBuilder<List<String>>(
            //   future: RestApi.listIngredients(),
            //   builder: (context, snapshot) {
            //     if (snapshot.hasData) {
            //       return IngredientsListView(ingredients: snapshot.data!);
            //     }
            //     return const Center(child: CircularProgressIndicator());
            //   },
            // ),
          ]);
        }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => const QrScan())),
          child: const Icon(Icons.qr_code_scanner),
        ),
      ),
    );
  }
}

//Lista Cocktails
class DrinksListView extends StatelessWidget {
  const DrinksListView({Key? key, required this.drinks}) : super(key: key);

  final List<Drink> drinks;

  @override
  Widget build(BuildContext context) {
    if (drinks.isEmpty) {
      return const Center(child: Text("No result found"));
    }

    return ListView.separated(
      itemCount: drinks.length,
      itemBuilder: (context, index) => DrinkTile(drink: drinks[index]),
      separatorBuilder: (context, index) => const Divider(height: 0),
      padding: const EdgeInsets.only(bottom: 56),
    );
  }
}

//Lista ingredienti
class IngredientsListView extends StatelessWidget {
  const IngredientsListView({Key? key, required this.ingredients})
      : super(key: key);

  final List<String> ingredients;

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return const Center(child: Text("No result found"));
    }

    return ListView.separated(
      itemCount: ingredients.length,
      itemBuilder: (context, index) => ListTile(
          onTap: () {
            context.read<DrinksModel>().filterByIngredient(ingredients[index]);
            DefaultTabController.of(context)!.animateTo(0);
          },
          title: Text(ingredients[index])),
      separatorBuilder: (context, index) => const Divider(height: 0),
      padding: const EdgeInsets.only(bottom: 56),
    );
  }
}

//Riga Cocktail
class DrinkTile extends StatelessWidget {
  final Drink drink;

  const DrinkTile({Key? key, required this.drink}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var model = context.watch<DrinksModel>();

    final favorite = model.favorites.contains(drink.id);

    return ListTile(
      onTap: () {
        showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Modal BottomSheet'),
                      ElevatedButton(
                        child: const Text('Close BottomSheet'),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
              );
            });
      },

      //  Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (_) => DrinkDetail(drink.id)),
      // ),
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(drink.preview),
      ),
      title: Text(drink.name),
      subtitle: Text(
        drink.ingredients.map((e) => e.name).toList().join(', '),
      ),
      trailing: IconButton(
        icon: favorite
            ? const Icon(Icons.favorite)
            : const Icon(Icons.favorite_border),
        onPressed: () {
          !model.favorites.contains(drink.id)
              ? model.addFavorite(drink.id)
              : model.removeFavorite(drink.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  favorite ? 'Removed from favorites.' : 'Added to favorites.'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

//Ricerca Cocktails
class DrinksSearchDelegate extends SearchDelegate {
  DrinksSearchDelegate(this.model);

  final DrinksModel model;

  @override
  String? get searchFieldLabel => "Search drink or ingredient";

  //Reset filtro di ricerca
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
    ];
  }

  //Chiusura pagina di ricerca
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final result = context.read<DrinksModel>().search(query);

    return DrinksListView(drinks: result);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final result = context.read<DrinksModel>().search(query);

    return DrinksListView(drinks: result);
  }
}
