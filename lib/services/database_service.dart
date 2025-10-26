import 'package:postgres/postgres.dart';
import 'env_config.dart';

class DatabaseService {
  static Connection? _connection;

  static Future<Connection> getConnection() async {
    if (_connection != null) {
      return _connection!;
    }

    final dbUrl = EnvConfig.databaseUrl;
    final uri = Uri.parse(dbUrl);

    _connection = await Connection.open(
      Endpoint(
        host: uri.host,
        database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres',
        username: uri.userInfo.split(':').first,
        password: uri.userInfo.split(':').last,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );

    print('✓ Connected to PostgreSQL database');
    return _connection!;
  }

  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
    print('✓ Database connection closed');
  }

  // CRUD operations for Professors
  static Future<List<Map<String, dynamic>>> getProfessors() async {
    final conn = await getConnection();
    final result = await conn.execute(
      'SELECT id, name, email, department, created_at FROM professors ORDER BY id'
    );

    return result.map((row) => {
      'id': row[0],
      'name': row[1],
      'email': row[2],
      'department': row[3],
      'created_at': row[4].toString(),
    }).toList();
  }

  static Future<Map<String, dynamic>> createProfessor(String name, String email, String department) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named('INSERT INTO professors (name, email, department) VALUES (@name, @email, @department) RETURNING id, name, email, department, created_at'),
      parameters: {
        'name': name,
        'email': email,
        'department': department,
      },
    );

    final row = result.first;
    return {
      'id': row[0],
      'name': row[1],
      'email': row[2],
      'department': row[3],
      'created_at': row[4].toString(),
    };
  }

  static Future<void> updateProfessor(int id, String name, String email, String department) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('UPDATE professors SET name = @name, email = @email, department = @department, updated_at = CURRENT_TIMESTAMP WHERE id = @id'),
      parameters: {
        'id': id,
        'name': name,
        'email': email,
        'department': department,
      },
    );
  }

  static Future<void> deleteProfessor(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM professors WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  // CRUD operations for Students
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final conn = await getConnection();
    final result = await conn.execute(
      'SELECT id, name, email, stream, enrollment_year, created_at FROM students ORDER BY id'
    );

    return result.map((row) => {
      'id': row[0],
      'name': row[1],
      'email': row[2],
      'stream': row[3],
      'enrollment_year': row[4],
      'created_at': row[5].toString(),
    }).toList();
  }

  static Future<Map<String, dynamic>> createStudent(String name, String email, String stream, int enrollmentYear) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named('INSERT INTO students (name, email, stream, enrollment_year) VALUES (@name, @email, @stream, @year) RETURNING id, name, email, stream, enrollment_year, created_at'),
      parameters: {
        'name': name,
        'email': email,
        'stream': stream,
        'year': enrollmentYear,
      },
    );

    final row = result.first;
    return {
      'id': row[0],
      'name': row[1],
      'email': row[2],
      'stream': row[3],
      'enrollment_year': row[4],
      'created_at': row[5].toString(),
    };
  }

  static Future<void> updateStudent(int id, String name, String email, String stream, int enrollmentYear) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('UPDATE students SET name = @name, email = @email, stream = @stream, enrollment_year = @year, updated_at = CURRENT_TIMESTAMP WHERE id = @id'),
      parameters: {
        'id': id,
        'name': name,
        'email': email,
        'stream': stream,
        'year': enrollmentYear,
      },
    );
  }

  static Future<void> deleteStudent(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM students WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  // CRUD operations for Lectures
  static Future<List<Map<String, dynamic>>> getLectures() async {
    final conn = await getConnection();
    final result = await conn.execute(
      '''SELECT l.id, l.title, l.description, l.professor_id, l.schedule, l.room,
         l.created_at, p.name as professor_name
         FROM lectures l
         LEFT JOIN professors p ON l.professor_id = p.id
         ORDER BY l.id'''
    );

    return result.map((row) => {
      'id': row[0],
      'title': row[1],
      'description': row[2],
      'professor_id': row[3],
      'schedule': row[4],
      'room': row[5],
      'created_at': row[6].toString(),
      'professor_name': row[7],
    }).toList();
  }

  static Future<Map<String, dynamic>> createLecture(String title, String description, int professorId, String schedule, String room) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named('INSERT INTO lectures (title, description, professor_id, schedule, room) VALUES (@title, @description, @professor_id, @schedule, @room) RETURNING id, title, description, professor_id, schedule, room, created_at'),
      parameters: {
        'title': title,
        'description': description,
        'professor_id': professorId,
        'schedule': schedule,
        'room': room,
      },
    );

    final row = result.first;
    return {
      'id': row[0],
      'title': row[1],
      'description': row[2],
      'professor_id': row[3],
      'schedule': row[4],
      'room': row[5],
      'created_at': row[6].toString(),
    };
  }

  static Future<void> updateLecture(int id, String title, String description, int professorId, String schedule, String room) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('UPDATE lectures SET title = @title, description = @description, professor_id = @professor_id, schedule = @schedule, room = @room, updated_at = CURRENT_TIMESTAMP WHERE id = @id'),
      parameters: {
        'id': id,
        'title': title,
        'description': description,
        'professor_id': professorId,
        'schedule': schedule,
        'room': room,
      },
    );
  }

  static Future<void> deleteLecture(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM lectures WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  // CRUD operations for Enrollments
  static Future<List<Map<String, dynamic>>> getEnrollments() async {
    final conn = await getConnection();
    final result = await conn.execute(
      '''SELECT e.id, e.student_id, e.lecture_id, e.enrolled_at,
         s.name as student_name, l.title as lecture_title
         FROM enrollments e
         JOIN students s ON e.student_id = s.id
         JOIN lectures l ON e.lecture_id = l.id
         ORDER BY e.id'''
    );

    return result.map((row) => {
      'id': row[0],
      'student_id': row[1],
      'lecture_id': row[2],
      'enrolled_at': row[3].toString(),
      'student_name': row[4],
      'lecture_title': row[5],
    }).toList();
  }

  static Future<Map<String, dynamic>> createEnrollment(int studentId, int lectureId) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named('INSERT INTO enrollments (student_id, lecture_id) VALUES (@student_id, @lecture_id) RETURNING id, student_id, lecture_id, enrolled_at'),
      parameters: {
        'student_id': studentId,
        'lecture_id': lectureId,
      },
    );

    final row = result.first;
    return {
      'id': row[0],
      'student_id': row[1],
      'lecture_id': row[2],
      'enrolled_at': row[3].toString(),
    };
  }

  static Future<void> deleteEnrollment(int id) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('DELETE FROM enrollments WHERE id = @id'),
      parameters: {'id': id},
    );
  }
}
