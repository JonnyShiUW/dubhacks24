// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// Dio is the api client we are using to make requests to the server
final dio = Dio();

var currId = 0;
var queue = <(int, PatientData)>[];

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
        appBar: AppBar(title: const Text('Vigil')),
        body: ToDoApp(),
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
          ElevatedButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientFrontEnd())
              );
            },
            child: const Text('Patient')
          ),
          ElevatedButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NurseFrontend())
              );
            },
            child: const Text('Nurse')
          ),
        ]
      ),
    );
  }
}

class NurseFrontend extends StatefulWidget {

  @override
  State<NurseFrontend> createState() => _NurseFrontend();
}


class _NurseFrontend extends State<NurseFrontend> {

  @override
  Widget build(BuildContext context) {
    // on empty
    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Queue')),
        body: Column(
          children: [
            const Center(child: Text("No items in queue")),
          ],
        ),
      );
    }

    // on not empty
    return Scaffold(
      appBar: AppBar(title: const Text('Queue')),
      body: Column(
        children: <Widget>[
          for (var tile in queue) 
            createTile('${tile.$2.name} Room ${tile.$2.room}', tile.$2.prio.nameOf, [tile.$2.time.toString(), tile.$2.desc], tile.$1)
        ],
      ),
    );
  }

  ExpansionTile createTile(String title, String subtitle, List<String> properties, int currentId) {
    return ExpansionTile(
      title: Text(title),
      subtitle: Text(subtitle),
      children: [
        for (String s in properties) ListTile(title: Text(s)),
        ElevatedButton(
          onPressed: () {
            setState(() {
              queue.removeWhere((element) => element.$1 == currentId);
            });
          },
          child: const Text("Delete"),
        )
      ],
    );
  }
}

class PatientData {
  PriorityRank prio;
  String desc;
  DateTime time;
  String name;
  int room;

  PatientData(this.prio, this.desc, this.time, this.name, this.room);
}

void stateHasChanged() {

}

// A new page that says 'Hello World'
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Page'),
      ),
      body: const Center(
        child: Text(
          'Hello World',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// A new stateful page for the Patient Frontend
class PatientFrontEnd extends StatefulWidget {
  @override
  _PatientFrontEndState createState() => _PatientFrontEndState();
}

class _PatientFrontEndState extends State<PatientFrontEnd> {
  PriorityRank? selectedOption; // To store the selected dropdown value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Frontend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What can I do for you today?',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PriorityRank>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select an option'),
                    value: selectedOption,
                    items: [
                      DropdownMenuItem(value: PriorityRank.Pain, child: Text(PriorityRank.Pain.nameOf)),
                      DropdownMenuItem(value: PriorityRank.Hygiene, child: Text(PriorityRank.Hygiene.nameOf)),
                      DropdownMenuItem(value: PriorityRank.Comfort, child: Text(PriorityRank.Comfort.nameOf)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value; // Store the selected value
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10), // Add spacing between the dropdown and the mic icon
                IconButton(
                  onPressed: () {
                    // Microphone listening functionality here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Microphone pressed')),
                    );
                  },
                  icon: const Icon(Icons.mic, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedOption != null) // Show submit button only if an option is selected
              ElevatedButton(
                onPressed: () {
                  // Handle the submit action
                  sendRequest();
                },
                child: const Text('Submit'),
              ),
          ],
        ),
      ),
    );
  }

  void sendRequest() {
    if (selectedOption != null) {
      queue.add((currId, PatientData(selectedOption as PriorityRank, "temp desc", DateTime.now(), "John Doe", 69)));
      currId++;
    }
  }
}

// lower number = higher priority
enum PriorityRank {
  Pain(1),
  Hygiene(2),
  Comfort(3);

  String get nameOf {
    switch(this) {
      case PriorityRank.Pain:
        return 'Pain';
      case PriorityRank.Hygiene:
        return 'Hygiene / Cleaning';
      case PriorityRank.Comfort:
        return 'Comfort';
      default:
        throw ArgumentError('invalid argument');
    }
  }

  const PriorityRank(this.prio);
  final int prio;
}
