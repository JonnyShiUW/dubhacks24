import 'package:flutter/services.dart' show rootBundle;

class User {
  final String username;
  final String password;
  final String name;
  final int room;

  User({
    required this.username,
    required this.password,
    required this.name,
    required this.room,
  });
}

// really janky method to parse the CSV and get users/passwords. Would be replaced by a secure login function for a full program.
Future<List<User>> loadUserData() async {
  try {
    final data = await rootBundle.loadString('data/userdata.txt');
    List<User> users = [];
    List<String> lines = data.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      List<String> parts = line.split(',');
      if (parts.length == 4) {
        users.add(User(
          username: parts[0],
          password: parts[1],
          name: parts[2],
          room: int.parse(parts[3]),
        ));
      }
    }
    return users;
  } catch (e) {
    print('Error loading user data: $e');
    throw e; // Re-throw the error to be caught in the FutureBuilder
  }
}

// really janky method to parse the CSV and tie patient notes to room number
Future<List<(int, String)>> loadPatientNotes() async {
  try {
    final data = await rootBundle.loadString('data/patientnotes.txt');
    List<(int, String)> ret = [];
    List<String> split = data.split('\n');
    
    for(String s in split) {
      List<String> ssplit = s.split(',');
      ret.add((int.parse(ssplit[0]), ssplit[1]));
    }

    return ret;
  } catch (e) {
    print('Error loading user data: $e');
    rethrow; // Re-throw the error to be caught in the FutureBuilder
  }
}
