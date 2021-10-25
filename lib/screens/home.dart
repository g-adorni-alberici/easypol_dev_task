import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/drink.dart';
import '../models/drinks_model.dart';
import '../widgets/error_screen.dart';
import 'drink_detail.dart';
import 'qr_scan.dart';

const kTabletBreakpoint = 800;

class HomePage extends StatelessWidget {
  static String routeName = '/home';

  const HomePage({Key? key}) : super(key: key);

  ///Controlla i permessi per la fotocamera e va alla scansione del QR
  Future _scanQr(BuildContext context) async {
    var status = await Permission.camera.status;

    //Apr le impostazioni
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permissions permanently denied")),
      );
      return;
    }

    if (status.isDenied) {
      //Richiesta permesso
      final result = await Permission.camera.request().isGranted;

      if (!result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permissions denied")),
        );

        return;
      }
    }

    Navigator.pushNamed(context, QrScan.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<DrinksModel>();

    //Pagina di errore
    if (model.error != null) {
      return Scaffold(
          body: ErrorScreen(
        error: model.error!,
        onRetry: () => model.getDrinks(),
      ));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
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
            //Uso un builder per ricavare il context con già il DefaultTabController
            Builder(builder: (context) {
              return PopupMenuButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  enabled: !model.loading,
                  onSelected: (result) {
                    model.filterByCategory('$result');
                    DefaultTabController.of(context)!.animateTo(0);
                  },
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
                          checked:
                              model.categoryFilterBy == kNonAlcoholicString,
                          child: const Text(kNonAlcoholicString),
                        ),
                        const PopupMenuDivider(),
                        for (String c in model.categories)
                          CheckedPopupMenuItem(
                            checked: c == model.categoryFilterBy,
                            value: c,
                            child: Text(c),
                          )
                      ]);
            }),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Text('COCKTAILS')),
              Tab(icon: Text('FAVORITES')),
              //Tab(icon: Text('INGREDIENTS')),
            ],
          ),
        ),
        body: model.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                Builder(builder: (context) {
                  final model = context.watch<DrinksModel>();

                  return Column(
                    children: [
                      if (model.categoryFilterBy != kNoFilterString)
                        ListTile(
                          title: Text("Category: ${model.categoryFilterBy}"),
                          trailing: IconButton(
                            onPressed: () =>
                                model.filterByCategory(kNoFilterString),
                            icon: const Icon(Icons.clear),
                          ),
                          tileColor: Colors.blue[100],
                        ),
                      Expanded(child: DrinksListView(drinks: model.drinks)),
                    ],
                  );
                }),
                DrinksListView(drinks: model.getFavorites()),
              ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _scanQr(context),
          child: const Icon(Icons.qr_code_scanner),
        ),
      ),
    );
  }
}

///Lista Cocktails
class DrinksListView extends StatelessWidget {
  const DrinksListView({Key? key, required this.drinks}) : super(key: key);

  final List<Drink> drinks;

  @override
  Widget build(BuildContext context) {
    if (drinks.isEmpty) {
      return const Center(child: Text("No result found"));
    }

    final width = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: drinks.length,
            itemBuilder: (context, index) => DrinkTile(drink: drinks[index]),
            separatorBuilder: (context, index) => const Divider(height: 0),
            padding: const EdgeInsets.only(bottom: 56),
          ),
        ),
        if (width > kTabletBreakpoint) const Expanded(child: DrinkDetail())
      ],
    );
  }
}

///Riga Cocktail
class DrinkTile extends StatelessWidget {
  final Drink drink;

  const DrinkTile({Key? key, required this.drink}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var model = context.watch<DrinksModel>();

    final favorite = model.favorites.contains(drink.id);

    final width = MediaQuery.of(context).size.width;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              drink.thumb.isEmpty ? null : NetworkImage(drink.preview),
        ),
        title: Text(drink.name),
        subtitle: Text(
          drink.ingredients.map((e) => e.name).toList().join(', '),
        ),
        trailing: IconButton(
          icon: favorite
              ? const Icon(Icons.favorite, color: Colors.red)
              : const Icon(Icons.favorite_border),
          onPressed: () {
            !model.favorites.contains(drink.id)
                ? model.addFavorite(drink.id)
                : model.removeFavorite(drink.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(favorite
                    ? 'Removed from favorites.'
                    : 'Added to favorites.'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        isThreeLine: true,
        onTap: () {
          if (width >= kTabletBreakpoint) {
            model.showDetails(drink.id);
          } else {
            model.selectedDrinkId = drink.id;
            Navigator.pushNamed(context, DrinkDetail.routeName);
          }
        },
        selected: model.selectedDrinkId == drink.id,
      ),
    );
  }
}

///Ricerca Cocktails
class DrinksSearchDelegate extends SearchDelegate {
  DrinksSearchDelegate(this.model);

  final DrinksModel model;

  @override
  String? get searchFieldLabel => "Search drink or ingredient";

  ///Reset filtro di ricerca
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
    ];
  }

  ///Chiusura pagina di ricerca
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  ///Ricerca definitiva
  @override
  Widget buildResults(BuildContext context) {
    final result = context.read<DrinksModel>().search(query);

    return DrinksListView(drinks: result);
  }

  ///Ricerca durante inserimento
  @override
  Widget buildSuggestions(BuildContext context) {
    final result = context.read<DrinksModel>().search(query);

    return DrinksListView(drinks: result);
  }
}
