import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseService {
  static const String databaseUrl = "https://test-63c55-default-rtdb.firebaseio.com";

  // --- Worker Operations ---
  static Future<Map<String, dynamic>> getWorkers() async {
    try {
      final response = await http.get(Uri.parse('$databaseUrl/workers.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching workers: $e");
    }
    return {};
  }

  static Future<bool> addWorker(Map<String, dynamic> workerData) async {
    try {
      final response = await http.post(
        Uri.parse('$databaseUrl/workers.json'),
        body: jsonEncode(workerData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error adding worker: $e");
      return false;
    }
  }

  // --- Admin Operations ---
  static Future<Map<String, dynamic>> getAdmins() async {
    try {
      final response = await http.get(Uri.parse('$databaseUrl/admins.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching admins: $e");
    }
    return {};
  }

  static Future<bool> addAdmin(Map<String, dynamic> adminData) async {
    try {
      final response = await http.post(
        Uri.parse('$databaseUrl/admins.json'),
        body: jsonEncode(adminData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error adding admin: $e");
      return false;
    }
  }

  // --- Attendance Operations ---
  static Future<Map<String, dynamic>> getAttendance() async {
    try {
      final response = await http.get(Uri.parse('$databaseUrl/attendance.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching attendance: $e");
    }
    return {};
  }

  static Future<bool> saveAttendance(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$databaseUrl/attendance/$id.json'),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error saving attendance: $e");
      return false;
    }
  }

  // --- Excuse Operations ---
  static Future<Map<String, dynamic>> getExcuses() async {
    try {
      final response = await http.get(Uri.parse('$databaseUrl/excuses.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching excuses: $e");
    }
    return {};
  }

  static Future<bool> addExcuse(Map<String, dynamic> excuseData) async {
    try {
      final response = await http.post(
        Uri.parse('$databaseUrl/excuses.json'),
        body: jsonEncode(excuseData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error adding excuse: $e");
      return false;
    }
  }

  static Future<bool> updateExcuseStatus(String key, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$databaseUrl/excuses/$key.json'),
        body: jsonEncode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating excuse: $e");
      return false;
    }
  }

  // --- Worker Modification & Deletion ---
  static Future<bool> deleteWorker(String key) async {
    try {
      final response = await http.delete(
        Uri.parse('$databaseUrl/workers/$key.json'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting worker: $e");
      return false;
    }
  }

  static Future<bool> updateWorkerSalary(String key, double salary) async {
    try {
      final response = await http.patch(
        Uri.parse('$databaseUrl/workers/$key.json'),
        body: jsonEncode({"salary": salary}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating worker salary: $e");
      return false;
    }
  }
}
