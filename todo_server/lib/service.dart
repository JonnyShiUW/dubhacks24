import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'supabase_helper.dart';

class Service {
    static Handler get handler {
        final router = Router();

        // This is where you can define all of your routes for your
        // server. Note that you should probably move these routes
        // into their own files if you start making a routes with
        // hierarchies but for this template, we'll just keep them here.
        router.get('/', (Request request) async {
            return Response.ok('Welcome to the todo server!');
        });

        // GET: Gets all of the todos from the database
        router.get('/get-todos', (Request request) async {
            return await SupabaseHelper.getTodos();
        });

        // POST: Creates a new todo in the database
        router.post('/create-todo', (Request request) async {
            Map<String, dynamic> body = jsonDecode(await request.readAsString());
            return await SupabaseHelper.createTodo(body);
        });

        // POST: Deletes a todo from the database
        router.post('/delete-todo', (Request request) async {
            Map<String, dynamic> body = jsonDecode(await request.readAsString());
            return await SupabaseHelper.deleteTodo(body);
        });

        // Ensures that any other route is a page not found
        router.all('/<ignored|.*>', (Request request) async {
            return Response.notFound('Page not found');
        });

        return router.call;
    }
}