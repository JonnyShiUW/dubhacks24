// These are the packages in the "pubspec.yaml" file
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

// These are the files in the "lib" directory
import 'package:todo_server/service.dart';

// Your host name, "localhost" is the default
const hostname = String.fromEnvironment("HOST_NAME", defaultValue: "localhost");

void main(List<String> args) async {
    // Command line arg for port, 8080 is the default
    var port = int.fromEnvironment("PORT", defaultValue: 8080);

    // Handle the requests using the `Service` class
    var handler = const shelf.Pipeline()
        // Middleware (can do auth here as well)
        .addMiddleware(_fixCORS)
        .addHandler(Service.handler);

    // Run the server!
    var server = await io.serve(handler, hostname, port);
    print('Serving at http://${server.address.host}:${server.port}');
}

// CORS headers
// You should change this eventually when you are running this in production to
// prevent any cross origin requests that you don't want... 
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': '*',
};

shelf.Response? _options(shelf.Request request) =>
    (request.method == 'OPTIONS') ? shelf.Response.ok(null, headers: corsHeaders) : null;

shelf.Response _cors(shelf.Response response) => response.change(headers: corsHeaders);

final _fixCORS = shelf.createMiddleware(requestHandler: _options, responseHandler: _cors);