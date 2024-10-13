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
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Fuck you')),
        body: const NurseFrontend(),
      ),
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
          ElevatedButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NurseFrontend())
              );
            },             child: const Text('Nurse')),
        ]
      ),
    );
  }
}

class NurseFrontend extends StatefulWidget {
  const NurseFrontend({super.key});

  @override
  State<NurseFrontend> createState() => _NurseFrontend();
}

class _NurseFrontend extends State<NurseFrontend> {
  var currId = 0;
  var queue = <(int, ExpansionTile)>[];

  @override
  Widget build(BuildContext context) {

    // on empty
    if(queue.isEmpty) {
      return Column(
        children: [
          const Center(child: Text("No items in queue")),
          ElevatedButton.icon(
          onPressed: () {
            setState(() {
              queue.add(createTile("temp$currId", "temp$currId", ["temp$currId"], currId));
              currId++;
            });
          },
          icon: const Icon(Icons.add),
          label: const Text("Add")
        )
        ]
      );
    }

    // on not empty
    return Column(
      children: <Widget>[
        for(var tile in queue)
          tile.$2,
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              queue.add(createTile("temp$currId", "temp$currId", ["temp$currId"], currId));
              currId++;
            });
          },
          icon: const Icon(Icons.add),
          label: const Text("Add")
        )
      ],
    );
  }

  (int, ExpansionTile) createTile(String title, String subtitle, properties, currentId) {
  return (currentId, ExpansionTile(
    title: Text(title),
    subtitle: Text(subtitle),
    children: [
      for (String s in properties)
        ListTile(title: Text(s)),
      ElevatedButton(
        onPressed: () {
          setState(() {
            queue.removeWhere((element) => element.$1 == currentId);
          });
        },
        child: const Text("Delete")
      )
    ]
  ));
}
}

