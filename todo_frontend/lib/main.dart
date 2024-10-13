// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dataParser.dart';
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
                MaterialPageRoute(builder: (context) => LoginScreen())
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
    queue.sort((a, b) => a.$2.prio.prio.compareTo(b.$2.prio.prio) != 0 ? a.$2.prio.prio.compareTo(b.$2.prio.prio) : a.$2.time.compareTo(b.$2.time));
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
  final User user;

  PatientFrontEnd({required this.user});
  @override
  _PatientFrontEndState createState() => _PatientFrontEndState();
}

class _PatientFrontEndState extends State<PatientFrontEnd> {
  PriorityRank? selectedOption; // To store the selected dropdown value
  bool requestSent = false;

  @override
  Widget build(BuildContext context) {
    if (requestSent) {
      // If request has been sent, show the message
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Frontend'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Request sent, please wait',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    } else {
      // If request has not been sent, show the request form
      return Scaffold(
        appBar: AppBar(
          title: const Text('Patient Frontend'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome, ${widget.user.name}.',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 10),
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
                        DropdownMenuItem(
                            value: PriorityRank.Pain,
                            child: Text(PriorityRank.Pain.nameOf)),
                        DropdownMenuItem(
                            value: PriorityRank.Hygiene,
                            child: Text(PriorityRank.Hygiene.nameOf)),
                        DropdownMenuItem(
                            value: PriorityRank.Comfort,
                            child: Text(PriorityRank.Comfort.nameOf)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value; // Store the selected value
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                      width:
                          10),
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
              if (selectedOption != null)
                // Show submit button only if an option is selected
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
  }

  void sendRequest() {
    if (selectedOption != null) {
      queue.add((
        currId,
        PatientData(
          selectedOption as PriorityRank,
          "Request description",
          DateTime.now(),
          widget.user.name,
          widget.user.room,
        ),
      ));
      currId++;

      setState(() {
        requestSent = true;
      });
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

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late Future<List<User>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Login')),
      body: FutureBuilder<List<User>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // While the future is loading, show a loading indicator
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If the future has an error, display it
            return Center(child: Text('Error loading user data'));
          } else {
            // Once the future is complete, display the login form
            List<User> users = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String username = _usernameController.text.trim();
                      String password = _passwordController.text.trim();

                      User? user;
                      for (var u in users) {
                        if (u.username == username && u.password == password) {
                          user = u;
                          break;
                        }
                      }

                      if (user != null) {
                        // Successful login
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientFrontEnd(user: user!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid username or password')),
                        );
                      }
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}