import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serena Taxi',
      home: Scaffold(
        appBar: AppBar(title: Text('Serena Taxi')),
        body: Center(child: Text('مرحبًا بك في تطبيق سيرينا')),
      ),
    );
  }
}
