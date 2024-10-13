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
