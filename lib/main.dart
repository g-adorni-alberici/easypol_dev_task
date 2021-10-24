import 'package:dev_task_adorni/screens/authentication.dart';
import 'package:dev_task_adorni/screens/drink_detail.dart';
import 'package:dev_task_adorni/screens/home.dart';
import 'package:dev_task_adorni/screens/qr_scan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/drinks_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DrinksModel>(
      create: (context) => DrinksModel(),
      child: MaterialApp(
        title: 'Gabor Dev Task',
        theme: ThemeData(
          primaryColor: Colors.grey[900],
          colorScheme: ColorScheme.light(
            primary: Colors.grey[900]!,
            secondary: Colors.amber,
          ),
        ),
        initialRoute: AuthenticationPage.routeName,
        routes: {
          AuthenticationPage.routeName: (context) => const AuthenticationPage(),
          NewPinPage.routeName: (context) => const NewPinPage(),
          HomePage.routeName: (context) => const HomePage(),
          DrinkDetail.routeName: (context) => const DrinkDetail(),
          QrScan.routeName: (context) => const QrScan(),
          GenerateQrPage.routeName: (context) => const GenerateQrPage(),
        },
      ),
    );
  }
}
