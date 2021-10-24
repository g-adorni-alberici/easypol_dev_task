import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/drink.dart';
import '../models/drinks_model.dart';
import '../services/rest_api.dart';
import '../widgets/error_screen.dart';
import 'home.dart';
import 'qr_scan.dart';

///Dettaglio cocktail
class DrinkDetail extends StatelessWidget {
  const DrinkDetail({Key? key}) : super(key: key);

  static String routeName = '/drink_detail';

  //Schermata di generazione QR + condivisione
  void _generateQr(BuildContext context, Drink drink) {
    Navigator.pushNamed(context, GenerateQrPage.routeName, arguments: drink);
  }

  @override
  Widget build(BuildContext context) {
    //Selezione da modello in modo da gestire smartphone / tablet
    final id = context.watch<DrinksModel>().selectedDrinkId;

    //Tema per intestazioni
    final headerStyle = Theme.of(context)
        .textTheme
        .subtitle1!
        .copyWith(fontWeight: FontWeight.bold);

    //Nessun cocktail selezionato
    if (id == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Drink>(
        future: RestApi.lookupCocktailDetail(id),
        builder: (context, snapshot) {
          final width = MediaQuery.of(context).size.width;

          //Eccezione, mostro una schermata di errore
          if (snapshot.hasError) {
            const errorScreen = ErrorScreen(
              error: 'Server error. Please check your network connection.',
            );
            if (width < kTabletBreakpoint) {
              return Scaffold(appBar: AppBar(), body: errorScreen);
            } else {
              return const Card(child: errorScreen);
            }
          }

          if (snapshot.hasData) {
            final d = snapshot.data!;

            //Widget principale
            final body = SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ListTile(
                    title: Text(d.name,
                        style: Theme.of(context).textTheme.headline6),
                    trailing: width < kTabletBreakpoint
                        ? null
                        : IconButton(
                            onPressed: () => _generateQr(context, d),
                            icon: const Icon(Icons.share_outlined)),
                  ),
                  Image.network(
                    d.thumb,
                    height: 400,
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Chip(label: Text(d.category)),
                        if (d.iba != null) Chip(label: Text('IBA: ${d.iba!}')),
                        if (d.glass != null) Chip(label: Text(d.glass!)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.only(left: 16, top: 16, right: 16),
                    child: Text('Instructions:', style: headerStyle),
                  ),
                  ListTile(title: Text(d.instructions!)),
                  Container(
                    padding:
                        const EdgeInsets.only(left: 16, top: 16, right: 16),
                    child: Text('Ingredients:', style: headerStyle),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => ListTile(
                      title: Row(
                        children: [
                          Text(d.ingredients[index].name),
                          const Spacer(),
                          Text(
                            d.ingredients[index].measure ?? '',
                            style: const TextStyle(color: Colors.black54),
                          )
                        ],
                      ),
                    ),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 0),
                    itemCount: d.ingredients.length,
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            );

            if (width < kTabletBreakpoint) {
              //Su smartphone è una nuova pagina
              return Scaffold(
                appBar: AppBar(),
                body: body,
                floatingActionButton: FloatingActionButton(
                  onPressed: () => _generateQr(context, d),
                  child: const Icon(Icons.share_outlined),
                ),
              );
            } else {
              //Su tablet è un widget a destra della schermata principale
              return Card(child: body);
            }
          }

          return const Center(child: CircularProgressIndicator());
        });
  }
}

//Generazione QR Code co possibilità di condivisione
class GenerateQrPage extends StatelessWidget {
  const GenerateQrPage({Key? key}) : super(key: key);

  static String routeName = '/generate_qr';

  //Genera un file temporaneo con il qr code e lo condivide
  void _share(Drink drink) async {
    //Creazione immagine QR
    final painter = QrPainter(
        data: "$kCheckQrCode${drink.id}",
        version: QrVersions.auto,
        gapless: true,
        emptyColor: Colors.white);

    final data = await painter.toImageData(512, format: ImageByteFormat.png);
    Uint8List pngBytes = data!.buffer.asUint8List();

    //Scrittura file temporaneo
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/qr.png').create();
    await file.writeAsBytes(pngBytes);

    //Condivisione file appena creato
    Share.shareFiles(
      ['${tempDir.path}/qr.png'],
      text: 'Easypol Cocktail - ${drink.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final drink = ModalRoute.of(context)!.settings.arguments as Drink;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImage(data: "$kCheckQrCode${drink.id}"),
              const SizedBox(height: 64),
              OutlinedButton.icon(
                  onPressed: () => _share(drink),
                  icon: const Icon(Icons.share),
                  label: const Text('SHARE'))
            ],
          ),
        ),
      ),
    );
  }
}
