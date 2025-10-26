import 'dart:html';
import 'dart:convert';
import 'dart:async';

// API Base URL
const String apiUrl = 'http://localhost:8080';
const String wsUrl = 'ws://localhost:8080/ws';

// WebSocket connection
WebSocket? webSocket;
List<Map<String, dynamic>> students = [];
List<Map<String, dynamic>> professors = [];
List<Map<String, dynamic>> lectures = [];
List<Map<String, dynamic>> enrollments = [];

// Edit mode tracking
int? editingStudentId;
int? editingProfessorId;
int? editingLectureId;

void main() {
  print('🚀 University Management System - Client Started');

  // Initialize tabs
  initializeTabs();

  // Connect to WebSocket
  connectWebSocket();

  // Load initial data
  loadAllData();

  // Setup form handlers
  setupFormHandlers();

  // Setup button handlers
  setupButtonHandlers();
}

// ============ WebSocket Connection ============
void connectWebSocket() {
  try {
    webSocket = WebSocket(wsUrl);

    webSocket!.onOpen.listen((event) {
      print('✓ Connected to WebSocket');
      updateConnectionStatus(true);
    });

    webSocket!.onMessage.listen((MessageEvent event) {
      final data = json.decode(event.data as String);
      handleWebSocketMessage(data);
    });

    webSocket!.onClose.listen((event) {
      print('✗ WebSocket connection closed');
      updateConnectionStatus(false);

      // Attempt to reconnect after 3 seconds
      Timer(Duration(seconds: 3), () {
        print('Attempting to reconnect...');
        connectWebSocket();
      });
    });

    webSocket!.onError.listen((event) {
      print('✗ WebSocket error: $event');
      updateConnectionStatus(false);
    });
  } catch (e) {
    print('Error connecting to WebSocket: $e');
    updateConnectionStatus(false);
  }
}

void updateConnectionStatus(bool connected) {
  final indicator = querySelector('#connection-indicator');
  final text = querySelector('#connection-text');

  if (connected) {
    indicator?.classes.remove('disconnected');
    indicator?.classes.add('connected');
    text?.text = 'Connected';
  } else {
    indicator?.classes.remove('connected');
    indicator?.classes.add('disconnected');
    text?.text = 'Disconnected';
  }
}

void handleWebSocketMessage(Map<String, dynamic> message) {
  print('Received WebSocket message: ${message['type']}');

  switch (message['type']) {
    case 'student_created':
    case 'student_updated':
    case 'student_deleted':
      loadStudents();
      break;
    case 'professor_created':
    case 'professor_updated':
    case 'professor_deleted':
      loadProfessors();
      break;
    case 'lecture_created':
    case 'lecture_updated':
    case 'lecture_deleted':
      loadLectures();
      break;
    case 'enrollment_created':
    case 'enrollment_deleted':
      loadEnrollments();
      break;
  }
}

// ============ Tab Navigation ============
void initializeTabs() {
  final tabs = querySelectorAll('.tab');
  for (final tab in tabs) {
    tab.onClick.listen((event) {
      final tabName = tab.getAttribute('data-tab');
      switchTab(tabName!);
    });
  }
}

void switchTab(String tabName) {
  // Remove active class from all tabs and contents
  querySelectorAll('.tab').forEach((tab) => tab.classes.remove('active'));
  querySelectorAll('.tab-content').forEach((content) => content.classes.remove('active'));

  // Add active class to selected tab and content
  querySelector('.tab[data-tab="$tabName"]')?.classes.add('active');
  querySelector('#$tabName-tab')?.classes.add('active');
}

// ============ Load Data ============
void loadAllData() {
  loadStudents();
  loadProfessors();
  loadLectures();
  loadEnrollments();
}

Future<void> loadStudents() async {
  try {
    final response = await HttpRequest.getString('$apiUrl/api/students');
    students = List<Map<String, dynamic>>.from(json.decode(response));
    renderStudentsTable();
  } catch (e) {
    print('Error loading students: $e');
    showError('Failed to load students');
  }
}

Future<void> loadProfessors() async {
  try {
    final response = await HttpRequest.getString('$apiUrl/api/professors');
    professors = List<Map<String, dynamic>>.from(json.decode(response));
    renderProfessorsTable();
    updateProfessorDropdowns();
  } catch (e) {
    print('Error loading professors: $e');
    showError('Failed to load professors');
  }
}

Future<void> loadLectures() async {
  try {
    final response = await HttpRequest.getString('$apiUrl/api/lectures');
    lectures = List<Map<String, dynamic>>.from(json.decode(response));
    renderLecturesTable();
    updateLectureDropdowns();
  } catch (e) {
    print('Error loading lectures: $e');
    showError('Failed to load lectures');
  }
}

Future<void> loadEnrollments() async {
  try {
    final response = await HttpRequest.getString('$apiUrl/api/enrollments');
    enrollments = List<Map<String, dynamic>>.from(json.decode(response));
    renderEnrollmentsTable();
  } catch (e) {
    print('Error loading enrollments: $e');
    showError('Failed to load enrollments');
  }
}

// ============ Render Tables ============
void renderStudentsTable() {
  final tbody = querySelector('#students-tbody');
  if (tbody == null) return;

  if (students.isEmpty) {
    tbody.innerHtml = '<tr><td colspan="6" class="loading">No students found</td></tr>';
    return;
  }

  tbody.innerHtml = '';
  for (final student in students) {
    final row = TableRowElement();
    row.children.add(TableCellElement()..text = student['id'].toString());
    row.children.add(TableCellElement()..text = student['name']);
    row.children.add(TableCellElement()..text = student['email']);
    row.children.add(TableCellElement()..text = student['stream']);
    row.children.add(TableCellElement()..text = student['enrollment_year'].toString());

    final actionsCell = TableCellElement();
    final actionsDiv = DivElement()..className = 'action-buttons';

    final editBtn = ButtonElement()
      ..className = 'btn btn-primary'
      ..text = 'Edit'
      ..onClick.listen((_) => editStudent(student));
    actionsDiv.append(editBtn);

    final deleteBtn = ButtonElement()
      ..className = 'btn btn-danger'
      ..text = 'Delete'
      ..onClick.listen((_) => deleteStudent(student['id']));
    actionsDiv.append(deleteBtn);

    actionsCell.append(actionsDiv);
    row.children.add(actionsCell);

    tbody.append(row);
  }
  updateStudentDropdowns();
}

void renderProfessorsTable() {
  final tbody = querySelector('#professors-tbody');
  if (tbody == null) return;

  if (professors.isEmpty) {
    tbody.innerHtml = '<tr><td colspan="5" class="loading">No professors found</td></tr>';
    return;
  }

  tbody.innerHtml = '';
  for (final professor in professors) {
    final row = TableRowElement();
    row.children.add(TableCellElement()..text = professor['id'].toString());
    row.children.add(TableCellElement()..text = professor['name']);
    row.children.add(TableCellElement()..text = professor['email']);
    row.children.add(TableCellElement()..text = professor['department']);

    final actionsCell = TableCellElement();
    final actionsDiv = DivElement()..className = 'action-buttons';

    final editBtn = ButtonElement()
      ..className = 'btn btn-primary'
      ..text = 'Edit'
      ..onClick.listen((_) => editProfessor(professor));
    actionsDiv.append(editBtn);

    final deleteBtn = ButtonElement()
      ..className = 'btn btn-danger'
      ..text = 'Delete'
      ..onClick.listen((_) => deleteProfessor(professor['id']));
    actionsDiv.append(deleteBtn);

    actionsCell.append(actionsDiv);
    row.children.add(actionsCell);

    tbody.append(row);
  }
}

void renderLecturesTable() {
  final tbody = querySelector('#lectures-tbody');
  if (tbody == null) return;

  if (lectures.isEmpty) {
    tbody.innerHtml = '<tr><td colspan="6" class="loading">No lectures found</td></tr>';
    return;
  }

  tbody.innerHtml = '';
  for (final lecture in lectures) {
    final row = TableRowElement();
    row.children.add(TableCellElement()..text = lecture['id'].toString());
    row.children.add(TableCellElement()..text = lecture['title']);
    row.children.add(TableCellElement()..text = (lecture['professor_name'] ?? 'N/A'));
    row.children.add(TableCellElement()..text = lecture['schedule']);
    row.children.add(TableCellElement()..text = lecture['room']);

    final actionsCell = TableCellElement();
    final actionsDiv = DivElement()..className = 'action-buttons';

    final editBtn = ButtonElement()
      ..className = 'btn btn-primary'
      ..text = 'Edit'
      ..onClick.listen((_) => editLecture(lecture));
    actionsDiv.append(editBtn);

    final deleteBtn = ButtonElement()
      ..className = 'btn btn-danger'
      ..text = 'Delete'
      ..onClick.listen((_) => deleteLecture(lecture['id']));
    actionsDiv.append(deleteBtn);

    actionsCell.append(actionsDiv);
    row.children.add(actionsCell);

    tbody.append(row);
  }
}

void renderEnrollmentsTable() {
  final tbody = querySelector('#enrollments-tbody');
  if (tbody == null) return;

  if (enrollments.isEmpty) {
    tbody.innerHtml = '<tr><td colspan="5" class="loading">No enrollments found</td></tr>';
    return;
  }

  tbody.innerHtml = '';
  for (final enrollment in enrollments) {
    final enrolledAt = DateTime.parse(enrollment['enrolled_at']).toLocal();
    final row = TableRowElement();
    row.children.add(TableCellElement()..text = enrollment['id'].toString());
    row.children.add(TableCellElement()..text = enrollment['student_name']);
    row.children.add(TableCellElement()..text = enrollment['lecture_title']);
    row.children.add(TableCellElement()..text = enrolledAt.toString().split('.')[0]);

    final actionsCell = TableCellElement();
    final actionsDiv = DivElement()..className = 'action-buttons';
    final deleteBtn = ButtonElement()
      ..className = 'btn btn-danger'
      ..text = 'Unenroll'
      ..onClick.listen((_) => deleteEnrollment(enrollment['id']));
    actionsDiv.append(deleteBtn);
    actionsCell.append(actionsDiv);
    row.children.add(actionsCell);

    tbody.append(row);
  }
}

// ============ Form Handlers ============
void setupFormHandlers() {
  // Student form
  querySelector('#student-form')?.onSubmit.listen((event) {
    event.preventDefault();
    addStudent();
  });

  // Professor form
  querySelector('#professor-form')?.onSubmit.listen((event) {
    event.preventDefault();
    addProfessor();
  });

  // Lecture form
  querySelector('#lecture-form')?.onSubmit.listen((event) {
    event.preventDefault();
    addLecture();
  });

  // Enrollment form
  querySelector('#enrollment-form')?.onSubmit.listen((event) {
    event.preventDefault();
    addEnrollment();
  });
}

// ============ CRUD Operations ============
Future<void> addStudent() async {
  final name = (querySelector('#student-name') as InputElement).value!;
  final email = (querySelector('#student-email') as InputElement).value!;
  final stream = (querySelector('#student-stream') as InputElement).value!;
  final year = int.parse((querySelector('#student-year') as InputElement).value!);

  try {
    if (editingStudentId != null) {
      // Update existing student
      await HttpRequest.request(
        '$apiUrl/api/students/$editingStudentId',
        method: 'PUT',
        sendData: json.encode({
          'name': name,
          'email': email,
          'stream': stream,
          'enrollment_year': year,
        }),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      showSuccess('Student updated successfully!');
      editingStudentId = null;
    } else {
      // Add new student
      await HttpRequest.request(
        '$apiUrl/api/students',
        method: 'POST',
        sendData: json.encode({
          'name': name,
          'email': email,
          'stream': stream,
          'enrollment_year': year,
        }),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      showSuccess('Student added successfully!');
    }

    hideAddStudentForm();
    (querySelector('#student-form') as FormElement).reset();
  } catch (e) {
    showError('Failed to save student: $e');
  }
}

void editStudent(Map<String, dynamic> student) {
  editingStudentId = student['id'];
  (querySelector('#student-name') as InputElement).value = student['name'];
  (querySelector('#student-email') as InputElement).value = student['email'];
  (querySelector('#student-stream') as InputElement).value = student['stream'];
  (querySelector('#student-year') as InputElement).value = student['enrollment_year'].toString();
  querySelector('#add-student-form h3')?.text = 'Edit Student';
  querySelector('#add-student-form')?.style.display = 'block';
}

Future<void> deleteStudent(int id) async {
  if (!window.confirm('Are you sure you want to delete this student?')) return;

  try {
    await HttpRequest.request('$apiUrl/api/students/$id', method: 'DELETE');
    showSuccess('Student deleted successfully!');
  } catch (e) {
    showError('Failed to delete student: $e');
  }
}

Future<void> addProfessor() async {
  final name = (querySelector('#professor-name') as InputElement).value!;
  final email = (querySelector('#professor-email') as InputElement).value!;
  final department = (querySelector('#professor-department') as InputElement).value!;

  try {
    if (editingProfessorId != null) {
      // Update existing professor
      await HttpRequest.request(
        '$apiUrl/api/professors/$editingProfessorId',
        method: 'PUT',
        sendData: json.encode({
          'name': name,
          'email': email,
          'department': department,
        }),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      showSuccess('Professor updated successfully!');
      editingProfessorId = null;
    } else {
      // Add new professor
      await HttpRequest.request(
        '$apiUrl/api/professors',
        method: 'POST',
        sendData: json.encode({
          'name': name,
          'email': email,
          'department': department,
        }),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      showSuccess('Professor added successfully!');
    }

    hideAddProfessorForm();
    (querySelector('#professor-form') as FormElement).reset();
  } catch (e) {
    showError('Failed to save professor: $e');
  }
}

void editProfessor(Map<String, dynamic> professor) {
  editingProfessorId = professor['id'];
  (querySelector('#professor-name') as InputElement).value = professor['name'];
  (querySelector('#professor-email') as InputElement).value = professor['email'];
  (querySelector('#professor-department') as InputElement).value = professor['department'];
  querySelector('#add-professor-form h3')?.text = 'Edit Professor';
  querySelector('#add-professor-form')?.style.display = 'block';
}

Future<void> deleteProfessor(int id) async {
  if (!window.confirm('Are you sure you want to delete this professor?')) return;

  try {
    await HttpRequest.request('$apiUrl/api/professors/$id', method: 'DELETE');
    showSuccess('Professor deleted successfully!');
  } catch (e) {
    showError('Failed to delete professor: $e');
  }
}

Future<void> addLecture() async {
  final title = (querySelector('#lecture-title') as InputElement).value!;
  final description = (querySelector('#lecture-description') as TextAreaElement).value!;
  final professorId = int.parse((querySelector('#lecture-professor') as SelectElement).value!);
  final schedule = (querySelector('#lecture-schedule') as InputElement).value!;
  final room = (querySelector('#lecture-room') as InputElement).value!;

  try {
    if (editingLectureId != null) {
      // Update existing lecture
      await HttpRequest.request(
        '$apiUrl/api/lectures/$editingLectureId',
        method: 'PUT',
        sendData: json.encode({
          'title': title,
          'description': description,
          'professor_id': professorId,
          'schedule': schedule,
          'room': room,
        }),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      showSuccess('Lecture updated successfully!');
      editingLectureId = null;
    } else {
      // Add new lecture
      await HttpRequest.request(
        '$apiUrl/api/lectures',
        method: 'POST',
        sendData: json.encode({
          'title': title,
          'description': description,
          'professor_id': professorId,
          'schedule': schedule,
          'room': room,
        }),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      showSuccess('Lecture added successfully!');
    }

    hideAddLectureForm();
    (querySelector('#lecture-form') as FormElement).reset();
  } catch (e) {
    showError('Failed to save lecture: $e');
  }
}

void editLecture(Map<String, dynamic> lecture) {
  editingLectureId = lecture['id'];
  updateProfessorDropdowns();
  (querySelector('#lecture-title') as InputElement).value = lecture['title'];
  (querySelector('#lecture-description') as TextAreaElement).value = lecture['description'];
  (querySelector('#lecture-professor') as SelectElement).value = lecture['professor_id'].toString();
  (querySelector('#lecture-schedule') as InputElement).value = lecture['schedule'];
  (querySelector('#lecture-room') as InputElement).value = lecture['room'];
  querySelector('#add-lecture-form h3')?.text = 'Edit Lecture';
  querySelector('#add-lecture-form')?.style.display = 'block';
}

Future<void> deleteLecture(int id) async {
  if (!window.confirm('Are you sure you want to delete this lecture?')) return;

  try {
    await HttpRequest.request('$apiUrl/api/lectures/$id', method: 'DELETE');
    showSuccess('Lecture deleted successfully!');
  } catch (e) {
    showError('Failed to delete lecture: $e');
  }
}

Future<void> addEnrollment() async {
  final studentId = int.parse((querySelector('#enrollment-student') as SelectElement).value!);
  final lectureId = int.parse((querySelector('#enrollment-lecture') as SelectElement).value!);

  try {
    await HttpRequest.request(
      '$apiUrl/api/enrollments',
      method: 'POST',
      sendData: json.encode({
        'student_id': studentId,
        'lecture_id': lectureId,
      }),
      requestHeaders: {'Content-Type': 'application/json'},
    );

    hideAddEnrollmentForm();
    (querySelector('#enrollment-form') as FormElement).reset();
    showSuccess('Student enrolled successfully!');
  } catch (e) {
    showError('Failed to enroll student: $e');
  }
}

Future<void> deleteEnrollment(int id) async {
  if (!window.confirm('Are you sure you want to unenroll this student?')) return;

  try {
    await HttpRequest.request('$apiUrl/api/enrollments/$id', method: 'DELETE');
    showSuccess('Student unenrolled successfully!');
  } catch (e) {
    showError('Failed to unenroll student: $e');
  }
}

// ============ Update Dropdowns ============
void updateProfessorDropdowns() {
  final select = querySelector('#lecture-professor') as SelectElement?;
  if (select == null) return;

  select.children.clear();
  select.append(OptionElement(data: 'Select Professor', value: ''));

  for (final professor in professors) {
    select.append(OptionElement(
      data: professor['name'],
      value: professor['id'].toString(),
    ));
  }
}

void updateStudentDropdowns() {
  final select = querySelector('#enrollment-student') as SelectElement?;
  if (select == null) return;

  select.children.clear();
  select.append(OptionElement(data: 'Select Student', value: ''));

  for (final student in students) {
    select.append(OptionElement(
      data: student['name'],
      value: student['id'].toString(),
    ));
  }
}

void updateLectureDropdowns() {
  final select = querySelector('#enrollment-lecture') as SelectElement?;
  if (select == null) return;

  select.children.clear();
  select.append(OptionElement(data: 'Select Lecture', value: ''));

  for (final lecture in lectures) {
    select.append(OptionElement(
      data: lecture['title'],
      value: lecture['id'].toString(),
    ));
  }
}

// ============ Button Handlers ============
void setupButtonHandlers() {
  // Students buttons
  querySelector('#add-student-btn')?.onClick.listen((_) => showAddStudentForm());
  querySelector('#cancel-student-btn')?.onClick.listen((_) => hideAddStudentForm());

  // Professors buttons
  querySelector('#add-professor-btn')?.onClick.listen((_) => showAddProfessorForm());
  querySelector('#cancel-professor-btn')?.onClick.listen((_) => hideAddProfessorForm());

  // Lectures buttons
  querySelector('#add-lecture-btn')?.onClick.listen((_) => showAddLectureForm());
  querySelector('#cancel-lecture-btn')?.onClick.listen((_) => hideAddLectureForm());

  // Enrollments buttons
  querySelector('#add-enrollment-btn')?.onClick.listen((_) => showAddEnrollmentForm());
  querySelector('#cancel-enrollment-btn')?.onClick.listen((_) => hideAddEnrollmentForm());
}

// ============ Form Visibility ============
void showAddStudentForm() {
  editingStudentId = null;
  (querySelector('#student-form') as FormElement).reset();
  querySelector('#add-student-form h3')?.text = 'Add New Student';
  querySelector('#add-student-form')?.style.display = 'block';
}

void hideAddStudentForm() {
  editingStudentId = null;
  (querySelector('#student-form') as FormElement).reset();
  querySelector('#add-student-form')?.style.display = 'none';
}

void showAddProfessorForm() {
  editingProfessorId = null;
  (querySelector('#professor-form') as FormElement).reset();
  querySelector('#add-professor-form h3')?.text = 'Add New Professor';
  querySelector('#add-professor-form')?.style.display = 'block';
}

void hideAddProfessorForm() {
  editingProfessorId = null;
  (querySelector('#professor-form') as FormElement).reset();
  querySelector('#add-professor-form')?.style.display = 'none';
}

void showAddLectureForm() {
  editingLectureId = null;
  (querySelector('#lecture-form') as FormElement).reset();
  querySelector('#add-lecture-form h3')?.text = 'Add New Lecture';
  querySelector('#add-lecture-form')?.style.display = 'block';
  updateProfessorDropdowns();
}

void hideAddLectureForm() {
  editingLectureId = null;
  (querySelector('#lecture-form') as FormElement).reset();
  querySelector('#add-lecture-form')?.style.display = 'none';
}

void showAddEnrollmentForm() {
  querySelector('#add-enrollment-form')?.style.display = 'block';
  updateStudentDropdowns();
  updateLectureDropdowns();
}

void hideAddEnrollmentForm() {
  querySelector('#add-enrollment-form')?.style.display = 'none';
}

// ============ Notifications ============
void showSuccess(String message) {
  final container = querySelector('.container');
  final messageDiv = DivElement()
    ..className = 'message success'
    ..text = message;

  container?.insertBefore(messageDiv, container.firstChild);

  Timer(Duration(seconds: 3), () {
    messageDiv.remove();
  });
}

void showError(String message) {
  final container = querySelector('.container');
  final messageDiv = DivElement()
    ..className = 'message error'
    ..text = message;

  container?.insertBefore(messageDiv, container.firstChild);

  Timer(Duration(seconds: 5), () {
    messageDiv.remove();
  });
}
