import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/drink.dart';
import '../services/rest_api.dart';
import 'qr_scan.dart';

class DrinkDetail extends StatelessWidget {
  const DrinkDetail(this.id, {Key? key}) : super(key: key);

  final int id;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context)
        .textTheme
        .subtitle1!
        .copyWith(fontWeight: FontWeight.bold);

    return FutureBuilder<Drink>(
        future: RestApi.lookupCocktailDetail(id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final d = snapshot.data!;

            return Scaffold(
              appBar: AppBar(),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text(d.name,
                          style: Theme.of(context).textTheme.headline6),
                    ),
                    Image.network(
                      d.thumb,
                      height: 300,
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
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => QrShare(d))),
                child: const Icon(Icons.qr_code),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        });
  }
}

//Generazione QR Code co possibilità di condivisione
class QrShare extends StatelessWidget {
  const QrShare(this.drink, {Key? key}) : super(key: key);

  final Drink drink;

  String get code => "$kCheckQrCode${drink.id}";

  //Genera un file temporaneo con il qr code e lo condivide
  void _share() async {
    final painter = QrPainter(
        data: code,
        version: QrVersions.auto,
        gapless: true,
        emptyColor: Colors.white);

    final tempDir = await getTemporaryDirectory();

    final data = await painter.toImageData(512, format: ImageByteFormat.png);
    Uint8List pngBytes = data!.buffer.asUint8List();

    final file = await File('${tempDir.path}/qr.png').create();
    await file.writeAsBytes(pngBytes);

    Share.shareFiles(
      ['${tempDir.path}/qr.png'],
      text: 'Easypol Cocktail - ${drink.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImage(data: code, size: 300),
            SizedBox(
              width: 300,
              child: OutlinedButton.icon(
                  onPressed: () => _share(),
                  icon: const Icon(Icons.share),
                  label: const Text('SHARE')),
            )
          ],
        ),
      ),
    );
  }
}
