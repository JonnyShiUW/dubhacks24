// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dataParser.dart';
// Dio is the api client we are using to make requests to the server
final dio = Dio();

// global variables
var currId = 0;
var queue = <(int, PatientData)>[];

// class to keep track of patient requests
class PatientData {
  PriorityRank prio;
  String desc;
  DateTime time;
  String name;
  int room;

  PatientData(this.prio, this.desc, this.time, this.name, this.room);
}

// lower number = higher priority
enum PriorityRank {
  urgent(0),
  pain(1),
  hygiene(2),
  comfort(3);

  // user friendly names
  String get nameOf {
    switch(this) {
      case PriorityRank.urgent:
        return 'Urgent / Emergency';
      case PriorityRank.pain:
        return 'Pain';
      case PriorityRank.hygiene:
        return 'Hygiene / Cleaning';
      case PriorityRank.comfort:
        return 'Comfort / Lifestyle';
      default:
        throw ArgumentError('invalid argument');
    }
  }

  const PriorityRank(this.prio);
  final int prio;
}

// Main: This is the entry point for your Flutter app
void main() {
  runApp(BaseApp());
}

// home theme
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

// login page
class ToDoApp extends StatelessWidget {
  //const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          const Text('Login'),
          ElevatedButton(onPressed: () {
              // navigate to login
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen())
              );
            },
            child: const Text('Patient')
          ),
          ElevatedButton(onPressed: () {
            // navigate to nurse frontend
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
  late Future<List<(int, String)>> _patientData;

  @override
  void initState() {
    super.initState();
    _patientData = loadPatientNotes();
  }

  @override
  Widget build(BuildContext context) {
    // queue is empty
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

    // queue is not empty, sort patient request queue by higher priority, then earlier time
    queue.sort((a, b) => a.$2.prio.prio.compareTo(b.$2.prio.prio) != 0 ? a.$2.prio.prio.compareTo(b.$2.prio.prio) : a.$2.time.compareTo(b.$2.time));
    return Scaffold(
      appBar: AppBar(title: const Text('Queue')),
      body: FutureBuilder(
        future: _patientData,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // While the future is loading, show a loading indicator
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If the future has an error, display it
            return Center(child: Text('Error loading user data'));
          } else {
            List<(int, String)> patientData = snapshot.data!;
            return Column(
              children: <Widget>[
                // build an expandable list for each request in queue
                for (var tile in queue)
                  createTile('${tile.$2.name} Room ${tile.$2.room}', tile.$2.prio.nameOf, [getTime(tile.$2.time.hour, tile.$2.time.minute, tile.$2.time.second), getPatientDesc(tile.$2.room, patientData)], tile.$1)
              ],
            );
          }
        } 
      )
    );
  }

  // helper method that creates and populates the exapandable lists
  ExpansionTile createTile(String title, String subtitle, List<String> properties, int currentId) {
    return ExpansionTile(
      title: Text(title),
      subtitle: Text(subtitle),
      children: [
        for (String s in properties) ListTile(title: Text(s)),
        ElevatedButton(
          onPressed: () {
            // map button press to delete the cooresponding request
            setState(() {
              queue.removeWhere((element) => element.$1 == currentId);
            });
          },
          child: const Text("Delete"),
        )
      ],
    );
  }

  // helper method that gets patient description from room number
  String getPatientDesc(int roomNum, List<(int, String)> patData) {
    return patData.firstWhere((a) => a.$1 == roomNum, orElse: () => (0, "No Patient Data Found")).$2;
  }

  // helper method to display correct times
  String getTime(int hours, int minutes, int seconds) {
    String h = hours < 10 ? '0$hours' : hours.toString();
    String m = minutes < 10 ? '0$minutes' : minutes.toString();
    String s = seconds < 10 ? '0$seconds' : seconds.toString();

    return '$h:$m:$s';
  }
}

// A new stateful page for the Patient Frontend
class PatientFrontEnd extends StatefulWidget {
  final User user;

  const PatientFrontEnd({required this.user});
  @override
  _PatientFrontEndState createState() => _PatientFrontEndState();
}

class _PatientFrontEndState extends State<PatientFrontEnd> {
  PriorityRank? selectedOption; // To store the selected dropdown value
  bool requestSent = false;

  @override
  Widget build(BuildContext context) {

    if (requestSent) {
      // If request has been sent, show message sent screen
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
                  // TODO: replace expanded w/ actionable text box that interacts with our AWS Bedrock integration
                  Expanded(
                    child: DropdownButtonFormField<PriorityRank>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select an option'),
                      value: selectedOption,
                      items: [
                        DropdownMenuItem(
                            value: PriorityRank.urgent,
                            child: Text(PriorityRank.urgent.nameOf)),
                        DropdownMenuItem(
                            value: PriorityRank.pain,
                            child: Text(PriorityRank.pain.nameOf)),
                        DropdownMenuItem(
                            value: PriorityRank.hygiene,
                            child: Text(PriorityRank.hygiene.nameOf)),
                        DropdownMenuItem(
                            value: PriorityRank.comfort,
                            child: Text(PriorityRank.comfort.nameOf)),
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
                      // TODO: Microphone listening functionality here
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

  // helper method to throw a request to the nurse queue
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

      // update this page's state
      setState(() {
        requestSent = true;
      });
    }
  }
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