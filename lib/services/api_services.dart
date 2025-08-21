import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:5000';
  static const Duration _timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  static Future<Map<String, dynamic>> login(String userId, {String? imageBase64}) async {
    if (userId.isEmpty) {
      return {"success": false, "message": "User ID is required"};
    }
    
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/verify"),
            headers: _headers,
            body: jsonEncode({
              "user_id": userId,
              "live_image": imageBase64,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Login failed: $e"};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String userId,
    required String name,
    required String email,
    required String designation,
    required String center,
    required List<String> imagesBase64,
  }) async {
    if (userId.isEmpty || name.isEmpty || imagesBase64.isEmpty) {
      return {"success": false, "message": "Required fields are missing"};
    }

    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/register"),
            headers: _headers,
            body: jsonEncode({
              "user_id": userId,
              "name": name,
              "email": email,
              "designation": designation,
              "center": center,
              "images": imagesBase64, // Send as list of images
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Registration failed: $e"};
    }
  }

  static Future<Map<String, dynamic>> logout(String userId) async {
    if (userId.isEmpty) {
      return {"success": false, "message": "User ID is required"};
    }

    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/logout"),
            headers: _headers,
            body: jsonEncode({"user_id": userId}),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Logout failed: $e"};
    }
  }

  static Future<Map<String, dynamic>> validateUser(String userId) async {
    if (userId.isEmpty) {
      return {"success": false, "message": "User ID is required"};
    }

    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/valid?user_id=$userId"),
            headers: _headers,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Validation failed: $e"};
    }
  }

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl),
            headers: _headers,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Server unreachable: $e"};
    }
  }

  static Future<Map<String, dynamic>> getUserImages(String userId) async {
    if (userId.isEmpty) {
      return {"success": false, "message": "User ID is required"};
    }

    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/user/$userId/images"),
            headers: _headers,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Failed to get user images: $e"};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Return the decoded response directly, preserving all fields
        return {
          "success": true,
          ...decoded, // Include all fields from backend response
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message": decoded["message"] ?? "Request failed",
          "statusCode": response.statusCode,
          "similarity": decoded["similarity"],
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Parse error: $e (Status: ${response.statusCode})",
        "statusCode": response.statusCode,
      };
    }
  }
}