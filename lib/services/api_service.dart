import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend server URL
  // Production (Render.com): Live backend URL
  static const String baseUrl = 'https://helpnovaproject.onrender.com/api';
  
  // For local development, uncomment below and comment the line above:
  // static const String baseUrl = 'http://192.168.0.149:5000/api';

  // Save token to shared preferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get token from shared preferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Remove token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
  }

  // Save user name
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  // Sign up user
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String bloodGroup,
    required String skill,
    required bool locationAllowed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'bloodGroup': bloodGroup,
          'skill': skill,
          'locationAllowed': locationAllowed,
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      // Check if response body is valid JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}. Please check if the backend server is running correctly.',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        // Save token
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        // Save user name
        if (data['user'] != null && data['user']['name'] != null) {
          await saveUserName(data['user']['name']);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Account created successfully',
          'user': data['user'],
        };
      } else {
        // Handle different error status codes
        String errorMessage = data['message'] ?? 'Signup failed. Please try again.';
        if (response.statusCode == 400) {
          errorMessage = data['message'] ?? 'Invalid input. Please check your information.';
        } else if (response.statusCode == 500) {
          errorMessage = data['message'] ?? 'Server error. Please try again later.';
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running at $baseUrl',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection and server URL.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save token
        await saveToken(data['token']);
        // Save user name
        if (data['user'] != null && data['user']['name'] != null) {
          await saveUserName(data['user']['name']);
        }
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Submit medical emergency request
  static Future<Map<String, dynamic>> submitMedicalRequest({
    required String patientCondition,
    required String description,
    required int numberOfPeople,
    String? photo,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/medical/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientCondition': patientCondition,
          'description': description,
          'numberOfPeople': numberOfPeople,
          'photo': photo,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Medical request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit medical request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit blood donation request
  static Future<Map<String, dynamic>> submitBloodRequest({
    required String bloodGroup,
    required String hospitalName,
    required String patientName,
    required int unitsRequired,
    required String urgencyLevel,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/blood/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bloodGroup': bloodGroup,
          'hospitalName': hospitalName,
          'patientName': patientName,
          'unitsRequired': unitsRequired,
          'urgencyLevel': urgencyLevel,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Blood request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit blood request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit accident report
  static Future<Map<String, dynamic>> submitAccidentRequest({
    required String accidentType,
    required int numberOfInjured,
    required String description,
    String? photo,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/accident/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'accidentType': accidentType,
          'numberOfInjured': numberOfInjured,
          'description': description,
          'photo': photo,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Accident report submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit accident report',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit ambulance request
  static Future<Map<String, dynamic>> submitAmbulanceRequest({
    required String patientCondition,
    required int patientAge,
    required double pickupLatitude,
    required double pickupLongitude,
    String? hospitalDestination,
    required String contactNumber,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ambulance/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientCondition': patientCondition,
          'patientAge': patientAge,
          'pickupLocation': {
            'latitude': pickupLatitude,
            'longitude': pickupLongitude,
          },
          'hospitalDestination': hospitalDestination,
          'contactNumber': contactNumber,
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ambulance request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit ambulance request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit mechanic request
  static Future<Map<String, dynamic>> submitMechanicRequest({
    required String vehicleType,
    required String problemType,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/mechanic/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehicleType': vehicleType,
          'problemType': problemType,
          'description': description,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mechanic request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit mechanic request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit electrician request
  static Future<Map<String, dynamic>> submitElectricianRequest({
    required String problemType,
    required String description,
    String? photo,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/electrician/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'problemType': problemType,
          'description': description,
          'photo': photo,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Electrician request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit electrician request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit volunteer request
  static Future<Map<String, dynamic>> submitVolunteerRequest({
    required String helpType,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/volunteer/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'helpType': helpType,
          'description': description,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Volunteer request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit volunteer request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Submit fire emergency request
  static Future<Map<String, dynamic>> submitFireEmergencyRequest({
    required String fireType,
    required String severityLevel,
    String? photo,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/fire/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fireType': fireType,
          'severityLevel': severityLevel,
          'photo': photo,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Fire emergency request submitted successfully',
          'request': data['request'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit fire emergency request',
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Get nearby requests
  static Future<Map<String, dynamic>> getNearbyRequests({
    required double latitude,
    required double longitude,
    double radius = 5.0, // Default 5km radius
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final url = '$baseUrl/nearby/nearby?latitude=$latitude&longitude=$longitude&radius=$radius';
      print('[API] Fetching nearby requests from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );
      
      print('[API] Nearby requests response status: ${response.statusCode}');
      print('[API] Nearby requests response body: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        print('[API] Nearby requests fetched: ${data['count'] ?? 0} requests');
        return {
          'success': true,
          'requests': data['requests'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        print('[API] Failed to fetch nearby requests: ${data['message'] ?? 'Unknown error'}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch nearby requests',
          'requests': [],
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
        'requests': [],
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
        'requests': [],
      };
    }
  }

  // Get accepted helpers for user's latest active request
  static Future<Map<String, dynamic>> getAcceptedHelpers({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
          'helpers': [],
        };
      }

      String url = '$baseUrl/helpers/my-latest-request/helpers';
      if (latitude != null && longitude != null) {
        url += '?latitude=$latitude&longitude=$longitude';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running.');
        },
      );

      // Handle 404 - endpoint might not exist on deployed backend
      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Feature not available. Please update backend or check if you have any active requests.',
          'helpers': [],
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
          'helpers': [],
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'helpers': data['helpers'] ?? [],
          'request': data['request'],
          'message': data['message'] ?? 'Helpers fetched successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch accepted helpers',
          'helpers': [],
        };
      }
    } on http.ClientException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please make sure the backend server is running.',
        'helpers': [],
      };
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
        'helpers': [],
      };
    }
  }

  // Update FCM token
  static Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'FCM token updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update FCM token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating FCM token: ${e.toString()}',
      };
    }
  }

  // Update user location
  static Future<Map<String, dynamic>> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Location updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Send emergency notification to nearby users
  static Future<Map<String, dynamic>> sendEmergencyNotification({
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/emergency/send-alert'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'description': description ?? 'Emergency SOS request',
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid server response. Status: ${response.statusCode}',
        };
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Emergency alert sent successfully',
          'notifiedUsers': data['notifiedUsers'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send emergency alert',
        };
      }
    } catch (e) {
      String errorMessage = 'Network error occurred. ';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage += 'Cannot reach the server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += 'Connection timeout. Please check if the server is running.';
      } else {
        errorMessage += e.toString();
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
}
