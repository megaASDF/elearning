import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username == 'admin' && password == 'admin') {
      return {
        'token': 'mock_token_admin',
        'user': {
          'id': '1',
          'username': 'admin',
          'displayName': 'Administrator',
          'email': 'admin@fit.edu',
          'role': 'instructor',
          'createdAt': DateTime.now().toIso8601String(),
        }
      };
    }
    
    return {
      'token': 'mock_token_student',
      'user': {
        'id': '2',
        'username': username,
        'displayName': username,
        'email': '$username@student.fit.edu',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      }
    };
  }

  // Semesters
  Future<List<dynamic>> getSemesters() async {
    // Mock implementation - replace with real API call
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'code': 'HK1-2024',
        'name': 'Semester 1, 2024-2025',
        'startDate': '2024-09-01T00:00:00.000Z',
        'endDate': '2025-01-15T00:00:00.000Z',
        'isCurrent': true,
      },
      {
        'id': '2',
        'code': 'HK2-2023',
        'name': 'Semester 2, 2023-2024',
        'startDate': '2024-02-01T00:00:00.000Z',
        'endDate': '2024-06-15T00:00:00.000Z',
        'isCurrent': false,
      },
    ];
    
    /* Real API implementation:
    final response = await http.get(
      Uri.parse('$baseUrl/semesters'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load semesters');
    */
  }

  Future<Map<String, dynamic>> createSemester(Map<String, dynamic> data) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'isCurrent': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    /* Real API implementation:
    final response = await http.post(
      Uri.parse('$baseUrl/semesters'),
      headers: await _getAuthHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create semester');
    */
  }

  Future<Map<String, dynamic>> updateSemester(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'id': id, ...data};
    
    /* Real API implementation:
    final response = await http.put(
      Uri.parse('$baseUrl/semesters/$id'),
      headers: await _getAuthHeaders(),
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update semester');
    */
  }

  Future<void> deleteSemester(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    /* Real API implementation:
    final response = await http.delete(
      Uri.parse('$baseUrl/semesters/$id'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete semester');
    }
    */
  }

  // Courses
  Future<List<dynamic>> getCourses(String semesterId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'semesterId': semesterId,
        'code': 'IT4409',
        'name': 'Web Programming & Applications',
        'description': 'Learn modern web development with React, Node.js, and databases',
        'instructorName': 'Administrator',
        'numberOfSessions': 15,
        'createdAt': DateTime.now().toIso8601String(),
        'groupCount': 3,
        'studentCount': 45,
      },
      {
        'id': '2',
        'semesterId': semesterId,
        'code': 'IT3103',
        'name': 'Object-Oriented Programming',
        'description': 'Master OOP concepts with Java',
        'instructorName': 'Administrator',
        'numberOfSessions': 15,
        'createdAt': DateTime.now().toIso8601String(),
        'groupCount': 2,
        'studentCount': 30,
      },
      {
        'id': '3',
        'semesterId': semesterId,
        'code': 'IT3320',
        'name': 'Database Systems',
        'description': 'SQL, NoSQL, and database design principles',
        'instructorName': 'Administrator',
        'numberOfSessions': 15,
        'createdAt': DateTime.now().toIso8601String(),
        'groupCount': 2,
        'studentCount': 40,
      },
    ];
  }

  Future<Map<String, dynamic>> getCourseDetails(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': courseId,
      'semesterId': '1',
      'code': 'IT4409',
      'name': 'Web Programming & Applications',
      'description': 'Learn modern web development with React, Node.js, and databases',
      'instructorName': 'Administrator',
      'numberOfSessions': 15,
      'createdAt': DateTime.now().toIso8601String(),
      'groupCount': 3,
      'studentCount': 45,
    };
  }

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'instructorName': 'Administrator',
      'createdAt': DateTime.now().toIso8601String(),
      'groupCount': 0,
      'studentCount': 0,
    };
  }

  Future<Map<String, dynamic>> updateCourse(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'id': id, ...data};
  }

  Future<void> deleteCourse(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Groups
  Future<List<dynamic>> getGroups(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'courseId': courseId,
        'name': 'Group 1',
        'studentCount': 15,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'courseId': courseId,
        'name': 'Group 2',
        'studentCount': 15,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'courseId': courseId,
        'name': 'Group 3',
        'studentCount': 15,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'studentCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> deleteGroup(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Students
  Future<List<dynamic>> getStudents(String courseId, {String? groupId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final allStudents = [
      {
        'id': '2',
        'username': 'student1',
        'displayName': 'Nguyen Van A',
        'email': 'student1@student.fit.edu',
        'role': 'student',
        'groupId': '1',
        'groupName': 'Group 1',
      },
      {
        'id': '3',
        'username': 'student2',
        'displayName': 'Tran Thi B',
        'email': 'student2@student.fit.edu',
        'role': 'student',
        'groupId': '1',
        'groupName': 'Group 1',
      },
      {
        'id': '4',
        'username': 'student3',
        'displayName': 'Le Van C',
        'email': 'student3@student.fit.edu',
        'role': 'student',
        'groupId': '2',
        'groupName': 'Group 2',
      },
    ];

    if (groupId != null) {
      return allStudents.where((s) => s['groupId'] == groupId).toList();
    }
    return allStudents;
  }

  Future<List<dynamic>> getAllStudents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '2',
        'username': 'student1',
        'displayName': 'Nguyen Van A',
        'email': 'student1@student.fit.edu',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'username': 'student2',
        'displayName': 'Tran Thi B',
        'email': 'student2@student.fit.edu',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '4',
        'username': 'student3',
        'displayName': 'Le Van C',
        'email': 'student3@student.fit.edu',
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }

  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'role': 'student',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> deleteStudent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Announcements
  Future<List<dynamic>> getAnnouncements(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'courseId': courseId,
        'title': 'Welcome to Web Programming Course',
        'content': 'Welcome everyone! This course will cover modern web development technologies including HTML, CSS, JavaScript, React, Node.js, and MongoDB. Please check the syllabus in the materials section.',
        'attachmentUrls': [],
        'groupIds': [],
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'authorName': 'Administrator',
        'commentCount': 5,
        'viewCount': 42,
      },
      {
        'id': '2',
        'courseId': courseId,
        'title': 'Assignment 1 Released',
        'content': 'Assignment 1 is now available in the Classwork tab. Please complete it before the deadline. Good luck!',
        'attachmentUrls': [],
        'groupIds': ['1', '2'],
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'authorName': 'Administrator',
        'commentCount': 12,
        'viewCount': 38,
      },
      {
        'id': '3',
        'courseId': courseId,
        'title': 'Mid-term Exam Schedule',
        'content': 'The mid-term exam will be held on Week 8. It will cover all topics from Week 1 to Week 7. Please prepare well.',
        'attachmentUrls': ['exam_schedule.pdf'],
        'groupIds': [],
        'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'authorName': 'Administrator',
        'commentCount': 3,
        'viewCount': 15,
      },
    ];
  }

  // ========== BLOCK 4: ASSIGNMENTS & SUBMISSIONS ==========
  
  // Assignment endpoints
  Future<List<dynamic>> getAssignments(String courseId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock data
    return [
      {
        'id': '1',
        'courseId': courseId,
        'groupIds': ['1', '2'],
        'title': 'HTML & CSS Fundamentals',
        'description': 'Create a responsive portfolio website using HTML5 and CSS3. The website should include: Home page, About page, Projects gallery, Contact form. Use CSS Grid or Flexbox for layout.',
        'attachments': ['assignment1_requirements.pdf', 'example_template.zip'],
        'startDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'deadline': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'lateDeadline': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'allowLateSubmission': true,
        'maxAttempts': 3,
        'allowedFileFormats': ['zip', 'html', 'css'],
        'maxFileSizeMB': 10.0,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'updatedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': '2',
        'courseId': courseId,
        'groupIds': ['1', '2', '3'],
        'title': 'JavaScript DOM Manipulation',
        'description': 'Build an interactive To-Do List application using vanilla JavaScript. Requirements: Add tasks, Mark as complete, Delete tasks, Filter (all/active/completed), Local storage persistence.',
        'attachments': ['starter_code.zip'],
        'startDate': DateTime.now().toIso8601String(),
        'deadline': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'lateDeadline': null,
        'allowLateSubmission': false,
        'maxAttempts': 2,
        'allowedFileFormats': ['zip', 'html', 'js', 'css'],
        'maxFileSizeMB': 5.0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'courseId': courseId,
        'groupIds': ['3'],
        'title': 'React Component Development',
        'description': 'Create a weather dashboard using React. Integrate with a weather API and display current conditions, 5-day forecast, and location search functionality.',
        'attachments': [],
        'startDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'deadline': DateTime.now().add(const Duration(days: 21)).toIso8601String(),
        'lateDeadline': DateTime.now().add(const Duration(days: 23)).toIso8601String(),
        'allowLateSubmission': true,
        'maxAttempts': 1,
        'allowedFileFormats': ['zip'],
        'maxFileSizeMB': 20.0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];
    
    /* Real API implementation:
    final response = await http.get(
      Uri.parse('$baseUrl/assignments?courseId=$courseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load assignments');
    */
  }

  Future<Map<String, dynamic>> getAssignmentById(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': assignmentId,
      'courseId': '1',
      'groupIds': ['1', '2'],
      'title': 'HTML & CSS Fundamentals',
      'description': 'Create a responsive portfolio website using HTML5 and CSS3. The website should include: Home page, About page, Projects gallery, Contact form. Use CSS Grid or Flexbox for layout.',
      'attachments': ['assignment1_requirements.pdf', 'example_template.zip'],
      'startDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'deadline': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'lateDeadline': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      'allowLateSubmission': true,
      'maxAttempts': 3,
      'allowedFileFormats': ['zip', 'html', 'css'],
      'maxFileSizeMB': 10.0,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    /* Real API implementation:
    final response = await http.post(
      Uri.parse('$baseUrl/assignments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create assignment');
    */
  }

  Future<Map<String, dynamic>> updateAssignment(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'id': id,
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    /* Real API implementation:
    final response = await http.put(
      Uri.parse('$baseUrl/assignments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update assignment');
    */
  }

  Future<void> deleteAssignment(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    /* Real API implementation:
    final response = await http.delete(
      Uri.parse('$baseUrl/assignments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete assignment');
    }
    */
  }

  // Submission endpoints
  Future<List<dynamic>> getSubmissions(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock data
    return [
      {
        'id': '1',
        'assignmentId': assignmentId,
        'studentId': '2',
        'studentName': 'Nguyen Van A',
        'studentEmail': 'student1@student.fit.edu',
        'files': ['submission_nguyen_van_a.zip'],
        'comment': 'Here is my submission. I completed all requirements.',
        'submittedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'attemptNumber': 1,
        'isLate': false,
        'grade': 95.0,
        'feedback': 'Excellent work! Clean code and great design.',
        'gradedAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': '2',
        'assignmentId': assignmentId,
        'studentId': '3',
        'studentName': 'Tran Thi B',
        'studentEmail': 'student2@student.fit.edu',
        'files': ['tran_thi_b_portfolio.zip'],
        'comment': 'My portfolio website submission.',
        'submittedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'attemptNumber': 2,
        'isLate': false,
        'grade': null,
        'feedback': null,
        'gradedAt': null,
      },
      {
        'id': '3',
        'assignmentId': assignmentId,
        'studentId': '4',
        'studentName': 'Le Van C',
        'studentEmail': 'student3@student.fit.edu',
        'files': ['le_van_c_assignment1.zip'],
        'comment': null,
        'submittedAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'attemptNumber': 1,
        'isLate': true,
        'grade': 80.0,
        'feedback': 'Good effort, but late submission. Some CSS issues.',
        'gradedAt': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      },
    ];
    
    /* Real API implementation:
    final response = await http.get(
      Uri.parse('$baseUrl/submissions?assignmentId=$assignmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load submissions');
    */
  }

  Future<List<dynamic>> getMySubmissions(String assignmentId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final allSubmissions = await getSubmissions(assignmentId);
    return allSubmissions.where((s) => s['studentId'] == studentId).toList();
  }

  Future<Map<String, dynamic>> submitAssignment(String assignmentId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'assignmentId': assignmentId,
      ...data,
      'submittedAt': DateTime.now().toIso8601String(),
      'grade': null,
      'feedback': null,
      'gradedAt': null,
    };
    
    /* Real API implementation:
    final response = await http.post(
      Uri.parse('$baseUrl/submissions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: json.encode({...data, 'assignmentId': assignmentId}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to submit assignment');
    */
  }

  Future<Map<String, dynamic>> gradeSubmission(String submissionId, double grade, String? feedback) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'id': submissionId,
      'grade': grade,
      'feedback': feedback,
      'gradedAt': DateTime.now().toIso8601String(),
    };
    
    /* Real API implementation:
    final response = await http.put(
      Uri.parse('$baseUrl/submissions/$submissionId/grade'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
      body: json.encode({'grade': grade, 'feedback': feedback}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to grade submission');
    */
  }

  Future<void> deleteSubmission(String submissionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    /* Real API implementation:
    final response = await http.delete(
      Uri.parse('$baseUrl/submissions/$submissionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete submission');
    }
    */
  }

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _getToken()}',
    };
  }


  // ========== BLOCK 5: QUIZZES & QUESTIONS ==========

// Question Bank endpoints
Future<List<dynamic>> getQuestions(String courseId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'courseId': courseId,
      'questionText': 'What does HTML stand for?',
      'choices': [
        'Hyper Text Markup Language',
        'High Tech Modern Language',
        'Home Tool Markup Language',
        'Hyperlinks and Text Markup Language'
      ],
      'correctAnswerIndex': 0,
      'difficulty': 'easy',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '2',
      'courseId': courseId,
      'questionText': 'Which CSS property controls text size?',
      'choices': ['font-size', 'text-size', 'font-style', 'text-style'],
      'correctAnswerIndex': 0,
      'difficulty': 'easy',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '3',
      'courseId': courseId,
      'questionText': 'What is the correct way to declare a JavaScript variable?',
      'choices': ['var name;', 'variable name;', 'v name;', 'declare name;'],
      'correctAnswerIndex': 0,
      'difficulty': 'medium',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '4',
      'courseId': courseId,
      'questionText': 'Which HTTP method is used to update a resource?',
      'choices': ['POST', 'GET', 'PUT', 'DELETE'],
      'correctAnswerIndex': 2,
      'difficulty': 'medium',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'id': '5',
      'courseId': courseId,
      'questionText': 'What is a closure in JavaScript?',
      'choices': [
        'A function with access to its outer scope',
        'A way to close the browser',
        'A type of loop',
        'A CSS property'
      ],
      'correctAnswerIndex': 0,
      'difficulty': 'hard',
      'createdAt': DateTime.now().toIso8601String(),
    },
  ];
}

Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    ...data,
    'createdAt': DateTime.now().toIso8601String(),
  };
}

Future<Map<String, dynamic>> updateQuestion(String id, Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return {'id': id, ...data};
}

Future<void> deleteQuestion(String id) async {
  await Future.delayed(const Duration(milliseconds: 500));
}

// Quiz endpoints
Future<List<dynamic>> getQuizzes(String courseId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'courseId': courseId,
      'groupIds': ['1', '2'],
      'title': 'HTML & CSS Basics Quiz',
      'description': 'Test your knowledge of HTML and CSS fundamentals',
      'openTime': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'closeTime': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'durationMinutes': 30,
      'maxAttempts': 2,
      'easyQuestions': 5,
      'mediumQuestions': 3,
      'hardQuestions': 2,
      'questionIds': ['1', '2', '3', '4', '5'],
      'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'id': '2',
      'courseId': courseId,
      'groupIds': ['1', '2', '3'],
      'title': 'JavaScript Fundamentals',
      'description': 'Quiz covering JavaScript basics, DOM, and ES6 features',
      'openTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'closeTime': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      'durationMinutes': 45,
      'maxAttempts': 1,
      'easyQuestions': 3,
      'mediumQuestions': 5,
      'hardQuestions': 2,
      'questionIds': [],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
  ];
}

Future<Map<String, dynamic>> createQuiz(Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    ...data,
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
}

Future<Map<String, dynamic>> updateQuiz(String id, Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return {'id': id, ...data, 'updatedAt': DateTime.now().toIso8601String()};
}

Future<void> deleteQuiz(String id) async {
  await Future.delayed(const Duration(milliseconds: 500));
}

// Quiz Attempt endpoints
Future<List<dynamic>> getQuizAttempts(String quizId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'quizId': quizId,
      'studentId': '2',
      'studentName': 'Nguyen Van A',
      'answers': {'1': 0, '2': 0, '3': 0, '4': 2, '5': 0},
      'score': 100.0,
      'startedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'submittedAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
      'attemptNumber': 1,
    },
    {
      'id': '2',
      'quizId': quizId,
      'studentId': '3',
      'studentName': 'Tran Thi B',
      'answers': {'1': 0, '2': 1, '3': 0, '4': 2, '5': 1},
      'score': 60.0,
      'startedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'submittedAt': DateTime.now().subtract(const Duration(hours: 23)).toIso8601String(),
      'attemptNumber': 1,
    },
  ];
}

Future<Map<String, dynamic>> startQuizAttempt(String quizId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'quizId': quizId,
    'startedAt': DateTime.now().toIso8601String(),
    'attemptNumber': 1,
  };
}

Future<Map<String, dynamic>> submitQuizAttempt(String attemptId, Map<String, int> answers) async {
  await Future.delayed(const Duration(milliseconds: 1000));
  // Calculate score (mock)
  final score = (answers.length * 20).toDouble(); // Simple calculation
  return {
    'id': attemptId,
    'answers': answers,
    'score': score,
    'submittedAt': DateTime.now().toIso8601String(),
  };
}


// ========== BLOCK 6: MATERIALS & FORUMS ==========

// Materials endpoints
Future<List<dynamic>> getMaterials(String courseId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'courseId': courseId,
      'title': 'Course Syllabus',
      'description': 'Complete syllabus for the Web Programming course',
      'fileUrls': ['syllabus_2024.pdf'],
      'links': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'authorName': 'Administrator',
      'viewCount': 125,
      'downloadCount': 98,
    },
    {
      'id': '2',
      'courseId': courseId,
      'title': 'HTML5 & CSS3 Guide',
      'description': 'Comprehensive guide covering HTML5 and CSS3 fundamentals',
      'fileUrls': ['html5_css3_guide.pdf', 'css_cheatsheet.pdf'],
      'links': ['https://developer.mozilla.org/en-US/docs/Web/HTML'],
      'createdAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      'authorName': 'Administrator',
      'viewCount': 87,
      'downloadCount': 65,
    },
  ];
}

Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    ...data,
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
    'viewCount': 0,
    'downloadCount': 0,
  };
}

Future<Map<String, dynamic>> updateMaterial(String id, Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return {'id': id, ...data, 'updatedAt': DateTime.now().toIso8601String()};
}

Future<void> deleteMaterial(String id) async {
  await Future.delayed(const Duration(milliseconds: 500));
}

// Forum endpoints
Future<List<dynamic>> getForumTopics(String courseId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'courseId': courseId,
      'title': 'Question about Assignment 1',
      'content': 'I have a question regarding the CSS Grid layout in Assignment 1. Can someone help?',
      'authorId': '2',
      'authorName': 'Nguyen Van A',
      'attachments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'replyCount': 8,
      'viewCount': 42,
    },
    {
      'id': '2',
      'courseId': courseId,
      'title': 'Best resources for learning React?',
      'content': 'Can anyone recommend good tutorials or documentation for React beginners?',
      'authorId': '3',
      'authorName': 'Tran Thi B',
      'attachments': [],
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'updatedAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'replyCount': 12,
      'viewCount': 67,
    },
  ];
}

Future<Map<String, dynamic>> createForumTopic(Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    ...data,
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
    'replyCount': 0,
    'viewCount': 0,
  };
}

Future<List<dynamic>> getForumReplies(String topicId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'topicId': topicId,
      'content': 'You can use display: grid; on the container and then define grid-template-columns.',
      'authorId': '1',
      'authorName': 'Administrator',
      'attachments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'parentReplyId': null,
    },
    {
      'id': '2',
      'topicId': topicId,
      'content': 'Thank you! That helps a lot.',
      'authorId': '2',
      'authorName': 'Nguyen Van A',
      'attachments': [],
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'parentReplyId': '1',
    },
  ];
}

Future<Map<String, dynamic>> createForumReply(String topicId, Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'topicId': topicId,
    ...data,
    'createdAt': DateTime.now().toIso8601String(),
  };
}

Future<void> deleteForumTopic(String id) async {
  await Future.delayed(const Duration(milliseconds: 500));
}

Future<void> deleteForumReply(String id) async {
  await Future.delayed(const Duration(milliseconds: 500));
}


// ========== BLOCK 7: NOTIFICATIONS & MESSAGING ==========

// Notifications endpoints
Future<List<dynamic>> getNotifications(String userId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'userId': userId,
      'type': 'assignment',
      'title': 'New Assignment Posted',
      'message': 'HTML & CSS Fundamentals assignment has been posted. Due in 7 days.',
      'relatedId': '1',
      'relatedType': 'assignment',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': '2',
      'userId': userId,
      'type': 'quiz',
      'title': 'Quiz Opening Soon',
      'message': 'JavaScript Fundamentals quiz opens in 24 hours.',
      'relatedId': '2',
      'relatedType': 'quiz',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    },
    {
      'id': '3',
      'userId': userId,
      'type': 'grade',
      'title': 'Assignment Graded',
      'message': 'Your HTML & CSS assignment has been graded. Score: 95/100',
      'relatedId': '1',
      'relatedType': 'submission',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': '4',
      'userId': userId,
      'type': 'deadline',
      'title': 'Assignment Deadline Approaching',
      'message': 'JavaScript DOM Manipulation assignment is due in 2 days.',
      'relatedId': '2',
      'relatedType': 'assignment',
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
    },
    {
      'id': '5',
      'userId': userId,
      'type': 'announcement',
      'title': 'New Course Announcement',
      'message': 'Mid-term exam schedule has been posted.',
      'relatedId': '3',
      'relatedType': 'announcement',
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
  ];
}

Future<void> markNotificationAsRead(String notificationId) async {
  await Future.delayed(const Duration(milliseconds: 300));
}

Future<void> markAllNotificationsAsRead(String userId) async {
  await Future.delayed(const Duration(milliseconds: 500));
}

Future<void> deleteNotification(String notificationId) async {
  await Future.delayed(const Duration(milliseconds: 300));
}

// Messaging endpoints
Future<List<dynamic>> getConversations(String userId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'otherUserId': '1',
      'otherUserName': 'Administrator',
      'lastMessage': 'Thank you for your question. I will review your assignment.',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'unreadCount': 2,
    },
  ];
}

Future<List<dynamic>> getMessages(String userId, String otherUserId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    {
      'id': '1',
      'senderId': userId,
      'senderName': 'Current User',
      'receiverId': otherUserId,
      'receiverName': 'Administrator',
      'content': 'Hello, I have a question about Assignment 1.',
      'attachments': [],
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    },
    {
      'id': '2',
      'senderId': otherUserId,
      'senderName': 'Administrator',
      'receiverId': userId,
      'receiverName': 'Current User',
      'content': 'Hello! What would you like to know?',
      'attachments': [],
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    },
    {
      'id': '3',
      'senderId': userId,
      'senderName': 'Current User',
      'receiverId': otherUserId,
      'receiverName': 'Administrator',
      'content': 'Can you clarify the requirements for the CSS Grid section?',
      'attachments': [],
      'isRead': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
    },
    {
      'id': '4',
      'senderId': otherUserId,
      'senderName': 'Administrator',
      'receiverId': userId,
      'receiverName': 'Current User',
      'content': 'Thank you for your question. I will review your assignment.',
      'attachments': [],
      'isRead': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
  ];
}

Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    ...data,
    'isRead': false,
    'createdAt': DateTime.now().toIso8601String(),
  };
}

Future<void> markMessageAsRead(String messageId) async {
  await Future.delayed(const Duration(milliseconds: 300));
}

// ========== BLOCK 9: PROFILE & SETTINGS ==========

Future<Map<String, dynamic>> getUserProfile(String userId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return {
    'id': userId,
    'username': userId == '1' ? 'admin' : 'student1',
    'displayName': userId == '1' ? 'Administrator' : 'Nguyen Van A',
    'email': userId == '1' ? 'admin@fit.edu' : 'student1@student.fit.edu',
    'role': userId == '1' ? 'instructor' : 'student',
    'avatarUrl': null,
    'phoneNumber': '+84 123 456 789',
    'bio': userId == '1' 
        ? 'Senior Lecturer at Faculty of Information Technology' 
        : 'Third-year student majoring in Computer Science',
    'department': 'Faculty of Information Technology',
    'studentId': userId == '1' ?  null : '20210001',
    'createdAt': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
}

Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return {
    'id': userId,
    ... data,
    'updatedAt': DateTime.now().toIso8601String(),
  };
}

Future<String> uploadAvatar(String userId, String filePath) async {
  await Future.delayed(const Duration(milliseconds: 1500));
  // In real implementation, upload to server and return URL
  return 'https://example.com/avatars/$userId. jpg';
}

Future<void> changePassword(String userId, String oldPassword, String newPassword) async {
  await Future.delayed(const Duration(milliseconds: 800));
  // Validate old password and update new password
  if (oldPassword != 'admin' && oldPassword != 'password') {
    throw Exception('Incorrect old password');
  }
}
}
