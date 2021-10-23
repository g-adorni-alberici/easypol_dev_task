import 'dart:io';

import 'package:dev_task_adorni/models/drinks_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'drink_detail.dart';

const kCheckQrCode = 'EASYPOL_COCKTAIL:';

class QrScan extends StatefulWidget {
  const QrScan({Key? key}) : super(key: key);

  static String routeName = '/qr_scan';

  @override
  State<StatefulWidget> createState() => _QrScanState();
}

class _QrScanState extends State<QrScan> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  //Scanner creato, imposto l'evento di lettura
  void _onQRViewCreated(QRViewController controller) {
    try {
      this.controller = controller;

      controller.scannedDataStream.listen((scanData) {
        //Metto in pausa altrimenti continua a leggere a raffica
        controller.pauseCamera();

        //Controllo il codice
        if (scanData.code.contains(kCheckQrCode)) {
          final id = int.tryParse(scanData.code.replaceAll(kCheckQrCode, ''));

          context.read<DrinksModel>().selectedDrink = id;

          if (id != null) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DrinkDetail()));

            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code is not valid.')),
        );

        controller.resumeCamera();
      });
    } on CameraException catch (e) {
      // Si verifica solitamente su iOS quando sono disattivati i permessi della fotocamere
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occured. Try again')),
      );
    }
  }

  //Verifica permessi fotocamera
  void _onPermissionSet(
      BuildContext context, QRViewController controller, bool permission) {
    if (!permission) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //Cambio dimensione del riquadro in base alla dimensione del dispositivo
    final size = MediaQuery.of(context).size;
    var scanArea = size.width < 400 || size.height < 400 ? 150.0 : 300.0;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.red,
              cutOutSize: scanArea,
            ),
            onPermissionSet: (controller, permission) =>
                _onPermissionSet(context, controller, permission),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await controller?.toggleFlash();
                    setState(() {});
                  },
                  icon: FutureBuilder<bool?>(
                    future: controller?.getFlashStatus(),
                    builder: (context, snapshot) {
                      final flash = snapshot.data ?? false;
                      return flash
                          ? const Icon(Icons.flash_on, color: Colors.white)
                          : const Icon(Icons.flash_off, color: Colors.white);
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
