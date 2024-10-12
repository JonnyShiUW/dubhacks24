import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:supabase/supabase.dart';

// These are defined via the command line when you run the server
final supabaseUrl = String.fromEnvironment('SUPABASE_URL');
final supabaseKey = String.fromEnvironment('SUPABASE_KEY');


class SupabaseHelper {
    static SupabaseClient client = SupabaseClient(supabaseUrl, supabaseKey);

    static Future<Response> getTodos() async {
        try {
            // Do a SELECT * FROM todo_table and return the results in a 200 response
            final response = await client.from('todo_table').select('*');
            return Response.ok(jsonEncode({"todos": response}));
        } catch (e) {
            // This is a 500 error
            return Response.internalServerError(body: e.toString());
        }
    }

    static Future<Response> createTodo(Map<String, dynamic> body) async {
        try {
            // You should probably do some validation here and throw
            // an error if the body is missing any required fields, etc
            final response = await client.from('todo_table').insert(body);
            if (response == null) {
                return Response.ok('');
            }
            return Response.ok(jsonEncode(response.data));
        } catch (e) {
            return Response.internalServerError(body: e.toString());
        }
    }

    static Future<Response> deleteTodo(Map<String, dynamic> body) async {
        try {
            // You should probably do some validation here and throw
            // an error if the body is missing any required fields, etc
            final response = await client.from('todo_table').delete().eq('id', body['id']);
            if (response == null) {
                return Response.ok('');
            }
            return Response.ok(jsonEncode(response.data));
        } catch (e) {
            return Response.internalServerError(body: e.toString());
        }
    }
}