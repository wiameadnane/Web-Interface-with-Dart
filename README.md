# University Management System

A modern, full-stack web application for managing university data including professors, students, lectures, and enrollments. Built with Dart and featuring real-time updates via WebSocket streams.

![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=flat&logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=flat&logo=css3&logoColor=white)

## Features

### Core Functionality
-  **Full CRUD Operations** - Create, Read, Update, and Delete for all entities
-  **Real-time Updates** - WebSocket streaming for instant data synchronization across all clients
-  **Relational Data Management** - Proper foreign key relationships between entities
-  **Responsive Design** - Mobile-friendly interface with modern UI/UX
-  **Form Validation** - Client-side validation for data integrity

### Entity Management
- =h<ë **Professors** - Manage professor information (name, email, department)
- =h<“ **Students** - Track student details (name, email, stream, enrollment year)
- =Ú **Lectures** - Organize lectures with professor assignments, schedules, and rooms
- =Ý **Enrollments** - Link students to lectures with enrollment tracking

### Real-time Features
- = Live data synchronization across multiple browser tabs
- =â Connection status indicator
- ¡ Instant updates when data changes
- = Success/error notifications

## Technologies Used

### Backend
- **Dart** - Server-side application logic
- **Shelf** - HTTP server framework
- **Shelf Router** - RESTful API routing
- **Shelf WebSocket** - Real-time bidirectional communication
- **PostgreSQL** - Database driver for Dart

### Frontend
- **Dart (compiled to JavaScript)** - Client-side application logic
- **HTML5** - Structure and markup
- **CSS3** - Styling with modern animations and responsive design
- **WebSocket API** - Real-time client communication

### Database
- **PostgreSQL** - Relational database
- **Neon** - Serverless PostgreSQL hosting

## Prerequisites

Before you begin, ensure you have the following installed:

- **Dart SDK** (version 3.0.0 or higher)
  - Download from: https://dart.dev/get-dart
  - Or install via Flutter SDK
- **Git** (optional, for version control)
- **A modern web browser** (Chrome, Firefox, Edge, Safari)

## Installation

### 1. Clone or Download the Project

```bash
cd C:\Users\YourUsername\Documents
git clone <repository-url>
cd dart_app
```

Or download and extract the ZIP file to your desired location.

### 2. Install Dependencies

Open a terminal in the project directory and run:

```bash
dart pub get
```

This will install all required packages:
- `shelf` - Web server
- `shelf_router` - Routing
- `shelf_web_socket` - WebSocket support
- `postgres` - PostgreSQL driver
- `dotenv` - Environment variable management
- `web` - Web development utilities

### 3. Database Setup

#### Create a Neon PostgreSQL Database

1. Go to [Neon](https://neon.tech) and create a free account
2. Create a new project
3. Copy your connection string (it should look like):
   ```
   postgresql://username:password@host.neon.tech/database?sslmode=require
   ```

#### Configure Environment Variables

Create a `.env` file in the project root:

```env
DATABASE_URL='postgresql://your_username:your_password@your_host.neon.tech/your_database?sslmode=require&channel_binding=require'
```

**Important:** Replace the connection string with your actual Neon database credentials.

#### Run Database Migrations

Open the Neon SQL Editor and execute the following SQL:

```sql
-- Create Professors table
CREATE TABLE professors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Students table
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    stream VARCHAR(100),
    enrollment_year INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Lectures table
CREATE TABLE lectures (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    professor_id INTEGER REFERENCES professors(id) ON DELETE CASCADE,
    schedule VARCHAR(100),
    room VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Enrollments table
CREATE TABLE enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    lecture_id INTEGER REFERENCES lectures(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, lecture_id)
);

-- Create indexes for performance
CREATE INDEX idx_lectures_professor ON lectures(professor_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_lecture ON enrollments(lecture_id);

-- Insert sample data (optional)
INSERT INTO professors (name, email, department) VALUES
    ('Dr. Smith', 'smith@university.edu', 'Computer Science'),
    ('Prof. Johnson', 'johnson@university.edu', 'Mathematics'),
    ('Dr. Williams', 'williams@university.edu', 'Physics');

INSERT INTO students (name, email, stream, enrollment_year) VALUES
    ('Alice Cooper', 'alice@student.edu', 'Computer Science', 2024),
    ('Bob Martinez', 'bob@student.edu', 'Computer Science', 2024),
    ('Carol White', 'carol@student.edu', 'Mathematics', 2023),
    ('David Brown', 'david@student.edu', 'Physics', 2024);

INSERT INTO lectures (title, description, professor_id, schedule, room) VALUES
    ('Data Structures', 'Introduction to data structures and algorithms', 1, 'Mon/Wed 10:00-11:30', 'Room 101'),
    ('Calculus I', 'Differential and integral calculus', 2, 'Tue/Thu 14:00-15:30', 'Room 202'),
    ('Quantum Mechanics', 'Introduction to quantum physics', 3, 'Mon/Wed 13:00-14:30', 'Room 303');

INSERT INTO enrollments (student_id, lecture_id) VALUES
    (1, 1), -- Alice enrolled in Data Structures
    (2, 1), -- Bob enrolled in Data Structures
    (3, 2), -- Carol enrolled in Calculus I
    (4, 3); -- David enrolled in Quantum Mechanics
```

### 4. Compile Frontend

Compile the Dart web code to JavaScript:

```bash
dart compile js web/main.dart -o web/main.dart.js
```

This creates `web/main.dart.js` which the browser will execute.

## Running the Application

### Start the Server

In your terminal, run:

```bash
dart run bin/server.dart
```

You should see:

```
=€ Starting University Management Server...
 Environment variables loaded from .env file
 Connected to PostgreSQL database
 Server running on http://127.0.0.1:8080
 WebSocket available at ws://127.0.0.1:8080/ws
 Open http://localhost:8080 in your browser
```

### Access the Application

Open your web browser and navigate to:

```
http://localhost:8080
```

### Stop the Server

Press `Ctrl + C` in the terminal to stop the server.

## Usage Guide

### Managing Professors

1. Click the **"Professors"** tab
2. Click **"Add Professor"** to create a new professor
3. Fill in the form:
   - Name (required)
   - Email (required)
   - Department (required)
4. Click **"Save"**
5. To edit: Click the **"Edit"** button next to any professor
6. To delete: Click the **"Delete"** button (confirmation required)

### Managing Students

1. Click the **"Students"** tab
2. Click **"Add Student"** to create a new student
3. Fill in the form:
   - Name (required)
   - Email (required)
   - Stream/Program (required)
   - Enrollment Year (required)
4. Click **"Save"**
5. To edit: Click the **"Edit"** button next to any student
6. To delete: Click the **"Delete"** button (confirmation required)

### Managing Lectures

1. **First, ensure professors exist** (lectures require a professor)
2. Click the **"Lectures"** tab
3. Click **"Add Lecture"** to create a new lecture
4. Fill in the form:
   - Title (required)
   - Description (required)
   - Select Professor from dropdown (required)
   - Schedule (e.g., "Mon/Wed 10:00-11:30")
   - Room (e.g., "Room 101")
5. Click **"Save"**
6. To edit: Click the **"Edit"** button next to any lecture
7. To delete: Click the **"Delete"** button (confirmation required)

### Managing Enrollments

1. **First, ensure students and lectures exist**
2. Click the **"Enrollments"** tab
3. Click **"Add Enrollment"** to enroll a student in a lecture
4. Select:
   - Student from dropdown (required)
   - Lecture from dropdown (required)
5. Click **"Enroll"**
6. To unenroll: Click the **"Unenroll"** button (confirmation required)

### Real-time Features

To test real-time updates:

1. Open the application in **two browser tabs**
2. In Tab 1: Add a new student
3. In Tab 2: Watch the student appear automatically!
4. Works for all CRUD operations across all entities

The green/red indicator in the header shows WebSocket connection status.

## Project Structure

```
dart_app/
   bin/
      server.dart              # Main server application
   lib/
      models/                  # (Future) Data models
      services/
          env_config.dart      # Environment configuration
          database_service.dart # Database operations
   web/
      index.html               # Main HTML page
      styles.css               # Application styling
      main.dart                # Client-side Dart code
      main.dart.js             # Compiled JavaScript
   .env                         # Environment variables (not in git)
   pubspec.yaml                 # Dart dependencies
   README.md                    # This file
```

## API Endpoints

### Professors
- `GET /api/professors` - Get all professors
- `POST /api/professors` - Create a new professor
- `PUT /api/professors/:id` - Update a professor
- `DELETE /api/professors/:id` - Delete a professor

### Students
- `GET /api/students` - Get all students
- `POST /api/students` - Create a new student
- `PUT /api/students/:id` - Update a student
- `DELETE /api/students/:id` - Delete a student

### Lectures
- `GET /api/lectures` - Get all lectures (with professor names)
- `POST /api/lectures` - Create a new lecture
- `PUT /api/lectures/:id` - Update a lecture
- `DELETE /api/lectures/:id` - Delete a lecture

### Enrollments
- `GET /api/enrollments` - Get all enrollments (with student and lecture names)
- `POST /api/enrollments` - Create a new enrollment
- `DELETE /api/enrollments/:id` - Delete an enrollment

### WebSocket
- `WS /ws` - WebSocket endpoint for real-time updates

## WebSocket Events

The server broadcasts the following events:

| Event Type | Description |
|------------|-------------|
| `student_created` | New student added |
| `student_updated` | Student information updated |
| `student_deleted` | Student removed |
| `professor_created` | New professor added |
| `professor_updated` | Professor information updated |
| `professor_deleted` | Professor removed |
| `lecture_created` | New lecture added |
| `lecture_updated` | Lecture information updated |
| `lecture_deleted` | Lecture removed |
| `enrollment_created` | Student enrolled in lecture |
| `enrollment_deleted` | Student unenrolled from lecture |

All clients receive these events and automatically refresh their data.

## Database Schema

### Relationships

```
professors (1)       < (many) lectures
students (1)       < (many) enrollments
lectures (1)       < (many) enrollments
```

### Tables

**professors**
- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR(100) NOT NULL)
- `email` (VARCHAR(100) UNIQUE NOT NULL)
- `department` (VARCHAR(100))
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**students**
- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR(100) NOT NULL)
- `email` (VARCHAR(100) UNIQUE NOT NULL)
- `stream` (VARCHAR(100))
- `enrollment_year` (INTEGER)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**lectures**
- `id` (SERIAL PRIMARY KEY)
- `title` (VARCHAR(200) NOT NULL)
- `description` (TEXT)
- `professor_id` (INTEGER FOREIGN KEY ’ professors)
- `schedule` (VARCHAR(100))
- `room` (VARCHAR(50))
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**enrollments**
- `id` (SERIAL PRIMARY KEY)
- `student_id` (INTEGER FOREIGN KEY ’ students)
- `lecture_id` (INTEGER FOREIGN KEY ’ lectures)
- `enrolled_at` (TIMESTAMP)
- `UNIQUE(student_id, lecture_id)` - Prevents duplicate enrollments

## Troubleshooting

### Port Already in Use

**Error:** `errno = 10048` or "Address already in use"

**Solution:**

**Option 1: Kill the process using port 8080**
```bash
# Windows
netstat -ano | findstr :8080
taskkill /F /PID <PID_NUMBER>

# Linux/Mac
lsof -i :8080
kill -9 <PID_NUMBER>
```

**Option 2: Change the port in `bin/server.dart`**
```dart
final server = await shelf_io.serve(handler, '127.0.0.1', 8081); // Changed from 8080
```

### Database Connection Failed

**Error:** Connection timeout or authentication failed

**Solution:**
1. Check your `.env` file has the correct DATABASE_URL
2. Verify your Neon database is active
3. Test the connection string in the Neon dashboard
4. Ensure firewall allows outbound connections

### WebSocket Not Connecting

**Error:** Red indicator, "Disconnected" status

**Solution:**
1. Check server is running on port 8080
2. Verify no CORS issues in browser console (F12)
3. Restart the server
4. Clear browser cache and refresh

### Changes Not Showing

**Problem:** Code changes don't appear in the browser

**Solution:**
1. Recompile the Dart web code:
   ```bash
   dart compile js web/main.dart -o web/main.dart.js
   ```
2. Hard refresh the browser: `Ctrl + Shift + R` or `Cmd + Shift + R`
3. Clear browser cache

### Form Not Submitting

**Problem:** Clicking "Save" does nothing

**Solution:**
1. Open browser console (F12) to check for JavaScript errors
2. Verify all required fields are filled
3. Check network tab for failed API requests
4. Restart the server

## Development

### Making Changes to Backend

1. Edit files in `bin/` or `lib/services/`
2. Restart the server: `Ctrl + C` then `dart run bin/server.dart`
3. Test the API endpoints

### Making Changes to Frontend

1. Edit `web/main.dart`, `web/index.html`, or `web/styles.css`
2. Recompile if you changed Dart code:
   ```bash
   dart compile js web/main.dart -o web/main.dart.js
   ```
3. Refresh browser: `F5` or `Ctrl + R`

### Adding New Features

1. Update database schema (add migrations in Neon SQL Editor)
2. Add/update endpoints in `bin/server.dart`
3. Add/update database methods in `lib/services/database_service.dart`
4. Update frontend in `web/main.dart` and `web/index.html`
5. Recompile and test

## Security Notes

  **Important Security Considerations:**

1. **Never commit `.env` file to version control**
   - Add `.env` to `.gitignore`
   - Keep database credentials secret

2. **This is a development/educational project**
   - Not production-ready as-is
   - No authentication or authorization
   - No input sanitization
   - No rate limiting

3. **For production use, add:**
   - User authentication (JWT, OAuth)
   - Input validation and sanitization
   - SQL injection prevention (using parameterized queries)
   - HTTPS/TLS encryption
   - Rate limiting
   - CORS configuration
   - Environment-specific configurations

## Future Enhancements

Potential features to add:

- [ ] User authentication and authorization
- [ ] Search and filtering functionality
- [ ] Pagination for large datasets
- [ ] Export data to CSV/PDF
- [ ] Email notifications
- [ ] File upload (profile pictures, documents)
- [ ] Academic calendar integration
- [ ] Grade management system
- [ ] Attendance tracking
- [ ] Reports and analytics dashboard
- [ ] Mobile app (using Flutter)
- [ ] Dark mode theme toggle

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -m "Add feature"`
4. Push to the branch: `git push origin feature-name`
5. Open a Pull Request

## License

This project is for educational purposes. Feel free to use and modify as needed.

## Support

For issues or questions:
- Check the Troubleshooting section above
- Open an issue on GitHub
- Review Dart documentation: https://dart.dev/guides
- Check PostgreSQL docs: https://www.postgresql.org/docs/

## Acknowledgments

- Built with [Dart](https://dart.dev/)
- Database hosted on [Neon](https://neon.tech/)
- Inspired by modern university management systems

---

**Built with d using Dart and PostgreSQL**
