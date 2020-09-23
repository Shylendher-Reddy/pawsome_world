import 'package:flutter/material.dart';
import 'package:pawsome_world/screens/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          scaffoldBackgroundColor: Color(0xFF000000),
          backgroundColor: Color(0xFF000000),
          accentColor: Color(0xFF0194F5),
          textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white))
      ),
      home: Home(),
    );
  }
}