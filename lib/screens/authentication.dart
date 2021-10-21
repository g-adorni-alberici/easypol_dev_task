import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  ///Per la demo salvo il PIN in modalità sicura
  final storage = const FlutterSecureStorage();

  ///Gestore autenticazione biometrica
  final auth = LocalAuthentication();

  ///PIN inserit
  final _pinController = TextEditingController();

  ///Caricamento parametri
  bool _loading = true;

  ///Eventuale errore
  String? _error;

  ///Se è già stato impostato un PIN
  bool _hasPin = false;

  ///Se l'impronta digitale è attiva sul dispositivo
  bool _hasFingerprint = false;

  @override
  void initState() {
    super.initState();

    _checkPinAndBiometrics();
  }

  ///Verifica che esista un PIN associato e l'impronta digitale
  Future _checkPinAndBiometrics() async {
    _hasPin = await storage.containsKey(key: 'pin');

    if (await auth.canCheckBiometrics) {
      final availableBiometrics = await auth.getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        _hasFingerprint = true;
      }
    }

    _loading = false;

    setState(() {});
  }

  //Autenticazione con impronta
  Future _biometricAuthenticate() async {
    bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the application');

    if (didAuthenticate) Navigator.pushReplacementNamed(context, '/home');
  }

  //Autenticazione con pin, quando ho inserito 6 cifre
  Future _pinAuthenticate(String pin) async {
    if (pin.length == 6) {
      final stored = await storage.read(key: 'pin');

      if (pin == stored) Navigator.pushReplacementNamed(context, '/home');

      //Se non è corretto cancello tutto
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Text("GABOR DEV TASK",
                style: Theme.of(context).textTheme.headline1),
            Expanded(
              child: Center(child: Builder(builder: (context) {
                //Caricamento e controllo parametri
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                //Form al centro
                return SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(builder: (context) {
                        //C'è già un pin impostato
                        if (_hasPin) {
                          return Column(
                            children: [
                              const Text("ENTER PIN NUMBER"),
                              TextFormField(
                                controller: _pinController,
                                onChanged: (text) => _pinAuthenticate(text),
                                autofocus: true,
                                maxLength: 6,
                                obscureText: true,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 52),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          );
                        }

                        //Bottone per impostare un PIN
                        return OutlinedButton(
                            onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NewPinForm(),
                                  ),
                                ),
                            child: const Text('SET NEW PIN'));
                      }),
                      const SizedBox(height: 64),
                      if (_hasFingerprint)
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.fingerprint),
                          onPressed: () => _biometricAuthenticate(),
                        )
                    ],
                  ),
                );
              })),
            ),
          ],
        ),
      ),
    );
  }
}

///Schermata per impostare un nuovo PIN
///Sono previste 2 schermate per controllo
class NewPinForm extends StatefulWidget {
  const NewPinForm({Key? key}) : super(key: key);

  static const routeName = '/pin';

  @override
  State<StatefulWidget> createState() => _NewPinFormState();
}

class _NewPinFormState extends State<NewPinForm> {
  ///Primo PIN inserito
  String? _pin1;

  final _pinController = TextEditingController();

  ///Controllo PIN
  void _checkPin(BuildContext context, String newPin) async {
    //Controllo quando raggiungo 6 cifre
    if (newPin.length != 6) return;

    if (_pin1 == null) {
      //Prima schermata

      //Chiedo PIN di controllo
      _pin1 = newPin;

      setState(() {});
    } else {
      //Seconda schermata

      //I 2 PIN inseriti corrispondono, salvo il PIN
      if (_pin1 == newPin) {
        const storage = FlutterSecureStorage();

        await storage.write(key: 'pin', value: newPin);

        //Uso pushReplacement in modo da ricaricare la schermata iniziale
        Navigator.pushReplacementNamed(context, '/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PIN different from the one previously inserted"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    //Cancello in ogni caso il PIN
    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_pin1 == null ? "SET PIN NUMBER" : "RE-ENTER PIN NUMBER"),
                TextFormField(
                  onChanged: (text) => _checkPin(context, text),
                  controller: _pinController,
                  autofocus: true,
                  maxLength: 6,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 52),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ));
  }
}

enum PinFormState { pin, newPin, newPin2, loading }
