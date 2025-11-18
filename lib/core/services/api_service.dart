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
    // Mock login for demo - replace with actual API call
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
    
    // Mock student login
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

  Future<List<dynamic>> getSemesters() async {
    // Mock data - replace with actual API call
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

  Future<List<dynamic>> getCourses(String semesterId) async {
    // Mock data - replace with actual API call
    return [
      {
        'id': '1',
        'semesterId': semesterId,
        'code': 'IT4409',
        'name': 'Web Programming & Applications',
        'description': 'Learn modern web development',
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
    ];
  }
}