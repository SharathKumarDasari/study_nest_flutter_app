import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../screens/login_screen.dart'; // Import to access currentUsername
import 'dart:io'; // For File handling

class ApiService {
  static const String baseUrl = 'http://192.168.15.241:3000'; // Replace with your computer's IP address

  // Utility method to sanitize subjectName for URLs
  String _sanitizeSubjectName(String subjectName) {
    // Remove invalid characters and encode the subjectName
    String sanitized = Uri.encodeComponent(subjectName.trim());
    debugPrint('Sanitized subjectName: $sanitized');
    return sanitized;
  }

  Future<List<dynamic>> getSubjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pages'));
      debugPrint('Get subjects response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Get subjects error: $e');
      rethrow;
    }
  }

  Future<void> createPage(String subjectName, int semester) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pages'),
        headers: {
          'Content-Type': 'application/json',
          'x-username': currentUsername ?? '',
        },
        body: jsonEncode({'name': subjectName, 'semester': semester}),
      );
      debugPrint('Create page response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 201) {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to create page';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Create page error: $e');
      rethrow;
    }
  }

  Future<void> deletePage(String subjectName) async {
    try {
      final sanitizedSubjectName = _sanitizeSubjectName(subjectName);
      final response = await http.delete(
        Uri.parse('$baseUrl/pages/$sanitizedSubjectName'),
        headers: {
          'x-username': currentUsername ?? '',
        },
      );
      debugPrint('Delete page response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to delete page';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Delete page error: $e');
      rethrow;
    }
  }

  Future<void> uploadFile(String subjectName, String filePath) async {
    try {
      if (currentUsername == null || currentUsername!.isEmpty) {
        throw Exception('Username not set. Please log in again.');
      }

      final sanitizedSubjectName = _sanitizeSubjectName(subjectName);

      // Read the file and convert to base64
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final base64File = base64Encode(fileBytes);

      final response = await http.post(
        Uri.parse('$baseUrl/pages/$sanitizedSubjectName/files'),
        headers: {
          'Content-Type': 'application/json',
          'x-username': currentUsername!,
        },
        body: jsonEncode({
          'name': filePath.split('/').last,
          'fileData': base64File,
          'contentType': 'application/pdf',
        }),
      );

      debugPrint('Upload file response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 201) {
        String error = 'Failed to upload file: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          error = errorJson['error'] ?? error;
        } catch (_) {
          error = '$error (Response: ${response.body})';
        }
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Upload file error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFiles(String subjectName) async {
    try {
      final sanitizedSubjectName = _sanitizeSubjectName(subjectName);
      final response = await http.get(Uri.parse('$baseUrl/pages/$sanitizedSubjectName/files'));
      debugPrint('Get files response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> files = jsonDecode(response.body);
        return files.map((file) {
          if (file is Map && file.containsKey('name') && file.containsKey('fileData') && file.containsKey('contentType')) {
            return {
              'name': file['name'] as String,
              'fileData': file['fileData'] as String, // Base64 string
              'contentType': file['contentType'] as String,
            };
          }
          throw const FormatException('Invalid file format in response');
        }).toList();
      } else {
        throw Exception('Failed to load files: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Get files error: $e');
      rethrow;
    }
  }

  Future<void> register(String username, String password, String role, String rollno) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password, 'role': role, 'rollno': rollno}),
      );
      debugPrint('Register response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 201) {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to register';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      debugPrint('Login response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] as String; // Returns 'student' or 'teacher'
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to login';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Clear any session-related data if needed
    // For now, we assume logout just navigates back to login screen
  }
}