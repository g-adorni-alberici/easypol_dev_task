import 'package:dev_task_adorni/screens/authentication.dart';
import 'package:dev_task_adorni/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/drinks_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DrinksModel>(
      create: (context) => DrinksModel(),
      child: MaterialApp(
        title: 'Gabor Dev Task',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: HomePage.routeName,
        routes: {
          AuthenticationPage.routeName: (context) => const AuthenticationPage(),
          NewPinForm.routeName: (context) => const NewPinForm(),
          HomePage.routeName: (context) => const HomePage(),
        },
      ),
    );
  }
}
