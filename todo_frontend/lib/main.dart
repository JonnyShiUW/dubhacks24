import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// Dio is the api client we are using to make requests to the server
final dio = Dio();

// Main: This is the entry point for your Flutter app
void main() {
  runApp(BaseApp());
}


class BaseApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyAppState>(
      create: (BuildContext context) => MyAppState(),
      child: MaterialApp(
        title: 'Vigil',
        theme: ThemeData(
          useMaterial3:true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 189, 224, 255))
        ),
        home: ToDoApp(),
      )
    );
  }
}

class MyAppState extends ChangeNotifier {

}

// StatelessWidget is a widget that keep track of any state.
class ToDoApp extends StatelessWidget {
  //const ToDoApp({super.key});

  // This method must be preset in every widget is is the
  // thing that is rendered to the screen.
  @override
  Widget build(BuildContext context) {
    // We are rendering a MaterialApp widget which
    // has arguments like a title, a theme, and a home page
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          const Text('Login'),
          ElevatedButton(onPressed: (){}, child: Text('Patient')),
          ElevatedButton(onPressed: (){}, child: Text('Nurse')),
        ]
      ),
    );
  }
}

