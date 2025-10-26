import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../lib/services/env_config.dart';
import '../lib/services/database_service.dart';

// Stream controller for broadcasting updates to all connected clients
final _updateController = StreamController<String>.broadcast();
final List<WebSocketChannel> _connectedClients = [];

void main() async {
  print('🚀 Starting University Management Server...\n');

  // Load environment variables
  await EnvConfig.load();

  // Connect to database
  await DatabaseService.getConnection();

  final app = Router();

  // CORS middleware
  Middleware corsMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type',
          });
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type',
        });
      },
    );
  }

  // WebSocket endpoint for real-time updates
  app.get('/ws', webSocketHandler((WebSocketChannel webSocket) {
    print('✓ New WebSocket client connected');
    _connectedClients.add(webSocket);

    // Send initial connection message
    webSocket.sink.add(json.encode({
      'type': 'connected',
      'message': 'Connected to real-time updates',
    }));

    // Listen for client disconnect
    webSocket.stream.listen(
      (message) {
        // Handle incoming messages if needed
      },
      onDone: () {
        _connectedClients.remove(webSocket);
        print('✗ WebSocket client disconnected');
      },
      onError: (error) {
        _connectedClients.remove(webSocket);
        print('✗ WebSocket error: $error');
      },
    );
  }));

  // Broadcast update to all connected clients
  void broadcastUpdate(String type, dynamic data) {
    final message = json.encode({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    for (var client in List.from(_connectedClients)) {
      try {
        client.sink.add(message);
      } catch (e) {
        _connectedClients.remove(client);
      }
    }
  }

  // ============ PROFESSORS ENDPOINTS ============
  app.get('/api/professors', (Request request) async {
    try {
      final professors = await DatabaseService.getProfessors();
      return Response.ok(
        json.encode(professors),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.post('/api/professors', (Request request) async {
    try {
      final body = json.decode(await request.readAsString());
      final professor = await DatabaseService.createProfessor(
        body['name'],
        body['email'],
        body['department'],
      );

      broadcastUpdate('professor_created', professor);

      return Response.ok(
        json.encode(professor),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.put('/api/professors/<id>', (Request request, String id) async {
    try {
      final body = json.decode(await request.readAsString());
      await DatabaseService.updateProfessor(
        int.parse(id),
        body['name'],
        body['email'],
        body['department'],
      );

      broadcastUpdate('professor_updated', {'id': int.parse(id), ...body});

      return Response.ok(
        json.encode({'message': 'Professor updated successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.delete('/api/professors/<id>', (Request request, String id) async {
    try {
      await DatabaseService.deleteProfessor(int.parse(id));
      broadcastUpdate('professor_deleted', {'id': int.parse(id)});

      return Response.ok(
        json.encode({'message': 'Professor deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // ============ STUDENTS ENDPOINTS ============
  app.get('/api/students', (Request request) async {
    try {
      final students = await DatabaseService.getStudents();
      return Response.ok(
        json.encode(students),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.post('/api/students', (Request request) async {
    try {
      final body = json.decode(await request.readAsString());
      final student = await DatabaseService.createStudent(
        body['name'],
        body['email'],
        body['stream'],
        body['enrollment_year'],
      );

      broadcastUpdate('student_created', student);

      return Response.ok(
        json.encode(student),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.put('/api/students/<id>', (Request request, String id) async {
    try {
      final body = json.decode(await request.readAsString());
      await DatabaseService.updateStudent(
        int.parse(id),
        body['name'],
        body['email'],
        body['stream'],
        body['enrollment_year'],
      );

      broadcastUpdate('student_updated', {'id': int.parse(id), ...body});

      return Response.ok(
        json.encode({'message': 'Student updated successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.delete('/api/students/<id>', (Request request, String id) async {
    try {
      await DatabaseService.deleteStudent(int.parse(id));
      broadcastUpdate('student_deleted', {'id': int.parse(id)});

      return Response.ok(
        json.encode({'message': 'Student deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // ============ LECTURES ENDPOINTS ============
  app.get('/api/lectures', (Request request) async {
    try {
      final lectures = await DatabaseService.getLectures();
      return Response.ok(
        json.encode(lectures),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.post('/api/lectures', (Request request) async {
    try {
      final body = json.decode(await request.readAsString());
      final lecture = await DatabaseService.createLecture(
        body['title'],
        body['description'],
        body['professor_id'],
        body['schedule'],
        body['room'],
      );

      broadcastUpdate('lecture_created', lecture);

      return Response.ok(
        json.encode(lecture),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.put('/api/lectures/<id>', (Request request, String id) async {
    try {
      final body = json.decode(await request.readAsString());
      await DatabaseService.updateLecture(
        int.parse(id),
        body['title'],
        body['description'],
        body['professor_id'],
        body['schedule'],
        body['room'],
      );

      broadcastUpdate('lecture_updated', {'id': int.parse(id), ...body});

      return Response.ok(
        json.encode({'message': 'Lecture updated successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.delete('/api/lectures/<id>', (Request request, String id) async {
    try {
      await DatabaseService.deleteLecture(int.parse(id));
      broadcastUpdate('lecture_deleted', {'id': int.parse(id)});

      return Response.ok(
        json.encode({'message': 'Lecture deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // ============ ENROLLMENTS ENDPOINTS ============
  app.get('/api/enrollments', (Request request) async {
    try {
      final enrollments = await DatabaseService.getEnrollments();
      return Response.ok(
        json.encode(enrollments),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.post('/api/enrollments', (Request request) async {
    try {
      final body = json.decode(await request.readAsString());
      final enrollment = await DatabaseService.createEnrollment(
        body['student_id'],
        body['lecture_id'],
      );

      broadcastUpdate('enrollment_created', enrollment);

      return Response.ok(
        json.encode(enrollment),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  app.delete('/api/enrollments/<id>', (Request request, String id) async {
    try {
      await DatabaseService.deleteEnrollment(int.parse(id));
      broadcastUpdate('enrollment_deleted', {'id': int.parse(id)});

      return Response.ok(
        json.encode({'message': 'Enrollment deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // Serve static files from web directory
  app.get('/<file|.*>', (Request request, String file) async {
    if (file.isEmpty || file == '/') {
      file = 'index.html';
    }

    final filePath = 'web/$file';
    final fileObj = File(filePath);

    if (await fileObj.exists()) {
      final contentType = _getContentType(file);
      final contents = await fileObj.readAsString();
      return Response.ok(
        contents,
        headers: {'Content-Type': contentType},
      );
    }

    return Response.notFound('File not found');
  });

  // Start server
  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(app.call);

  final server = await shelf_io.serve(handler, '127.0.0.1', 8080);
  print('\n✓ Server running on http://${server.address.host}:${server.port}');
  print('✓ WebSocket available at ws://${server.address.host}:${server.port}/ws');
  print('✓ Open http://localhost:8080 in your browser\n');
}

String _getContentType(String path) {
  if (path.endsWith('.html')) return 'text/html';
  if (path.endsWith('.css')) return 'text/css';
  if (path.endsWith('.js')) return 'application/javascript';
  if (path.endsWith('.json')) return 'application/json';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
  return 'text/plain';
}
