import 'package:dev_task_adorni/models/drinks_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key? key}) : super(key: key);

  static String routeName = '/';

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  ///Gestore autenticazione biometrica
  final auth = LocalAuthentication();

  ///PIN inserito
  final _pinController = TextEditingController();

  ///Caricamento parametri
  bool _loading = true;

  ///Se è già stato impostato un PIN
  bool _hasPin = false;

  ///Se l'impronta digitale è attiva sul dispositivo
  bool _hasFingerprint = false;

  @override
  void initState() {
    super.initState();

    _checkPinAndBiometrics();
  }

  ///Verifica che esista un PIN associato e che il dispositivo supporti l'impronta digitale
  Future _checkPinAndBiometrics() async {
    final prefs = await SharedPreferences.getInstance();

    _hasPin = prefs.containsKey('pin');

    if (!kIsWeb && await auth.canCheckBiometrics) {
      final availableBiometrics = await auth.getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        _hasFingerprint = true;
      }
    }

    _loading = false;

    setState(() {});
  }

  ///Autenticazione con impronta
  Future _biometricAuthenticate() async {
    try {
      bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to access the application');

      if (didAuthenticate) {
        context.read<DrinksModel>().getDrinks();
        Navigator.pushNamedAndRemoveUntil(
            context, HomePage.routeName, (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Biometric Authentication not available. Required security features not enabled")),
      );
    }
  }

  ///Autenticazione con PIN
  Future _pinAuthenticate(String value) async {
    final prefs = await SharedPreferences.getInstance();

    final pin = prefs.getString('pin');

    if (pin == value) {
      context.read<DrinksModel>().getDrinks();
      Navigator.pushNamedAndRemoveUntil(
          context, HomePage.routeName, (route) => false);
    } else {
      _pinController.text = "";
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN is not valid.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark, // 2
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 64),
              Text("GABOR DEV TASK",
                  style: Theme.of(context).textTheme.headline4),
              Expanded(
                child: Center(
                  child: Builder(
                    builder: (context) {
                      //Caricamento e controllo parametri
                      if (_loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      //Form al centro
                      return SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(builder: (context) {
                              //C'è già un pin impostato
                              if (_hasPin) {
                                return PinCodeTextField(
                                  appContext: context,
                                  autoFocus: true,
                                  length: 6,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  enablePinAutofill: false,
                                  controller: _pinController,
                                  onCompleted: (value) =>
                                      _pinAuthenticate(value),
                                  onChanged: (value) {},
                                );
                              }

                              //Bottone per impostare un nuovo PIN
                              return OutlinedButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, NewPinPage.routeName),
                                  child: const Text('SET NEW PIN'));
                            }),
                            const SizedBox(height: 64),
                            if (_hasFingerprint)
                              IconButton(
                                iconSize: 56,
                                icon: const Icon(Icons.fingerprint),
                                onPressed: () => _biometricAuthenticate(),
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///Schermata per impostare un nuovo PIN
///Per simulare l'impostazione del codice utilizzo shared_preferences
class NewPinPage extends StatefulWidget {
  const NewPinPage({Key? key}) : super(key: key);

  static const routeName = '/pin';

  @override
  State<StatefulWidget> createState() => _NewPinPageState();
}

class _NewPinPageState extends State<NewPinPage> {
  ///Se != null vuol dire che sono nella seconda schermata di controllo
  String? _pin1;

  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  //Il dispose viene già gestito da pin_code_fields

  ///Controllo PIN
  void _checkPin(BuildContext context, String newPin) async {
    if (_pin1 == null) {
      //Prima schermata

      //Chiedo PIN di controllo
      setState(() {
        _pin1 = newPin;
      });

      //Cancello in ogni caso il PIN
      _pinController.clear();
    } else {
      //Seconda schermata

      //I 2 PIN inseriti corrispondono, salvo il PIN
      if (_pin1 == newPin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pin', newPin);

        //Ritorno alla schermata iniziale
        Navigator.pushNamedAndRemoveUntil(
            context, AuthenticationPage.routeName, (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PIN doesn't match")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //In questo modo apre direttamente la tastiera
    WidgetsBinding.instance!
        .addPostFrameCallback((_) => _focusNode.requestFocus());

    return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _pin1 == null
                      ? "ENTER NEW PIN NUMBER"
                      : "RE-ENTER PIN NUMBER",
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 32),
                PinCodeTextField(
                  appContext: context,
                  controller: _pinController,
                  focusNode: _focusNode,
                  length: 6,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  enablePinAutofill: false,
                  onCompleted: (value) async => _checkPin(context, value),
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ));
  }
}
