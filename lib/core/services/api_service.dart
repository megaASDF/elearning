class ApiService {
  // TODO: Replace with your actual backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  
  String? _token;

  void setToken(String? token) {
    _token = token;
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
  }

  Future<Map<String, dynamic>> createSemester(Map<String, dynamic> data) async {
    // Mock response
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      ...data,
      'isCurrent': false,
    };
  }

  Future<Map<String, dynamic>> updateSemester(String id, Map<String, dynamic> data) async {
    return {'id': id, ...data};
  }

  Future<void> deleteSemester(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Courses
  Future<List<dynamic>> getCourses(String semesterId) async {
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
    return {'id': id, ...data};
  }

  Future<void> deleteCourse(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Groups
  Future<List<dynamic>> getGroups(String courseId) async {
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
}