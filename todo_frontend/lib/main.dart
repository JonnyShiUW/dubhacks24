import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// Dio is the api client we are using to make requests to the server
final dio = Dio();

// Main: This is the entry point for your Flutter app
void main() {
  runApp(const ToDoApp());
}

// StatelessWidget is a widget that keep track of any state.
class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  // This method must be preset in every widget is is the
  // thing that is rendered to the screen.
  @override
  Widget build(BuildContext context) {
    // We are rendering a MaterialApp widget which
    // has arguments like a title, a theme, and a home page
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Heres how you pass in an argument to a custom widget
      home: const ToDoList(title: 'To-Do List'),
    );
  }
}

// StatefulWidget is a widget that keeps track of state!
// State is data tracked at the global level of the widget
// like class variables in Java. However, you must call setState
// to actually change them.
class ToDoList extends StatefulWidget {
  // Defualt constructor
  const ToDoList({super.key, required this.title});

  // Constant state variable
  final String title;
  

  @override
  State<ToDoList> createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  // A Future is a type that represents a value that will be available
  // in the "future". This is because api requests are asynchronous
  // and therefore take time to return a value. So this Future will take
  // time to update.
  late Future<List<Todo>> _todos;
  // This is a controller for the text field in the dialog that pops up (to keep
  // track of what the user types in the text field)
  final TextEditingController _textFieldController = TextEditingController();

  // This is the first thing that is called when the widget is created
  @override
  void initState() {
    super.initState();
    _todos = _getTodos();
  }

  // This gets a list of all todos from the database and returns a future
  Future<List<Todo>> _getTodos() async {
    try {
      // This is how you can do a GET request with dio. Note that here,
      // I use the async/await syntax instead of the .then() syntax. You
      // can use either! (in the add/remove methods, I use the .then() syntax)
      final response = await dio.get('http://localhost:8080/get-todos');
      var data = json.decode(response.data)['todos'] as List<dynamic>;
      List<Todo> newTodos = data.map((todo) =>
        // You should use a factory to create this. I am just lazy lol
        Todo(
          id: todo['id'],
          description: todo['description'],
        )
      ).toList();
      return newTodos;
    } catch (error) {
      // If there is an error, I just return an empty list, but this is not
      // ideal because the user will have no idea that there was an error. You
      // should probably handle errors better than this.
      print(error);
      return <Todo>[];
    }
  }

  // This is the function that is called when you add a new widget.
  // It takes in a description of the item and adds it to the database.
  // Note that we do not need to pass in an id, because the database will
  // automatically generate one for us.
  void _addTodoItem(String description) async {
    try {
      // This is how you make a POST request with dio
      dio.post(
        'http://localhost:8080/create-todo',
        // This is the body of the request. It is a JSON string
        data: json.encode({
          'description': description
        })
      ).then((value) => {
        // When the request is done, set the todos to a new list.
        // We need to call set state to re-render the ToDoList widget.
        // Try removing the setState and see what happens!. When you add
        // a todo item, it will not show up (even though it gets added
        // to the database). You will have to refresh the page to see it.
        setState(() {
          _todos = _getTodos();
        })
      });
    } catch (error) {
      // You should probably handle errors better than just printing them lol
      print(error);
    }
  }

  // This is the function that is called when you click the delete button
  // per todo item. It takes in a todo and deletes it from the database.
  void _deleteTodo(Todo todo) {
    try {
      // This is how you make a POST request with dio
      dio.post(
        'http://localhost:8080/delete-todo',
        // This is the body of the request. It is a JSON string
        data: json.encode({
          'id': todo.id
        })
      ).then((value) => {
        // When the request is done, set the todos to a new list.
        // We need to call set state to re-render the ToDoList widget.
        // Try removing the setState and see what happens!. Wehn you delete
        // a todo item, it will not disappear (even though it gets deleted
        // from the database). You will have to refresh the page to see it
        // disappear.
        setState(() {
          _todos = _getTodos();
        })
      });
    } catch (error) {
      // You should probably handle errors better than just printing them lol
      print(error);
    }
  }

  // Remember that every widget must have a build method and this is called
  // every time there is a rerender. One easy way to cause a rerender is to 
  // setState
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Try changing the color of this app bar!
      appBar: AppBar(
        backgroundColor: Colors.pink.shade100,
        title: Text(widget.title),
      ),
      body: Center(
        // This is a bit complicated...
        // FutureBuilder allows us to easily manage Futures. In this case,
        // we are displaying a circular progress indicator while the Future
        // is not ready. Once the Future is ready, we display the list of
        // Todos. If there is an error, we display the error. (The future we
        // are keeping track of is _todos)
        child: FutureBuilder<List<Todo>>(
          future: _todos,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              // If the future is not ready, display a circular progress indicator
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              // If the future is ready, display a list of todos
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: snapshot.data!.map((Todo todo) {
                  return TodoItem(
                      todo: todo,
                      removeTodo: _deleteTodo
                  );
                }).toList(),
              );
            } else if (snapshot.hasError) {
              // If there is an error, display the error
              return Text("${snapshot.error}");
            }
            // Else, just display a circular progress indicator
            // as a backup in case something weird happens lol
            return const CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(),
        tooltip: 'Add a Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  // This is the floating dialog that pops up when you click the
  // add button. It has a text field and two buttons.
  Future<void> _displayDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // The title of the dialog
          title: const Text('Add a todo'),
          // The text content of the dialog
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Type your todo'),
            autofocus: true,
          ),
          actions: <Widget>[
            // "Cancel" button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // "Add" button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _addTodoItem(_textFieldController.text);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}


// This is a custom object I am using to represent a Todo
class Todo {
  // A todo has an id and a description. The id must be unique
  Todo({
    required this.id,
    required this.description,
  });
  int id;
  String description;
}

// This is a custom widget I am using to represent a TodoItem.
// Note how this is stateless because we do not need to track anything
// about the TodoItem. It is just a widget that takes in a Todo and renders it.
// You should probably move these to seperate files to make it easier to read :)
class TodoItem extends StatelessWidget {
  TodoItem({
      required this.todo,
      required this.removeTodo,
  }) : super(key: ObjectKey(todo));

  final Todo todo;
  final void Function(Todo todo) removeTodo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(children: <Widget>[
        Expanded(
          child: Text(todo.description),
        ),
        IconButton(
          iconSize: 30,
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          alignment: Alignment.centerRight,
          onPressed: () {
            removeTodo(todo);
          },
        ),
      ]),
    );
  }
}

