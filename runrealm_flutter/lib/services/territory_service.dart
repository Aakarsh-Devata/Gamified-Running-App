import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class TerritoryService {
  // For testing on phone: replace with your computer's IP address
  // Find it with: ifconfig (Mac/Linux) or ipconfig (Windows)
  // Example: 'http://192.168.1.100:8080'
  // For emulator/Chrome: use 'http://localhost:8080'
  static const String baseUrl = 'https://runrealm-api-575506408098.us-central1.run.app';
  //static const String baseUrl = 'http://192.168.31.123:8080';
  
  
  /// Creates a territory by sending path coordinates directly
  /// This avoids the need for the API to have Firestore read permissions
  static Future<Map<String, dynamic>?> createTerritory({
    required String runId,
    required List<Map<String, double>> path,
  }) async {
    try {
      // Get current user's Firebase ID token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: No authenticated user');
        return null;
      }
      
      final token = await user.getIdToken();
      if (token == null) {
        print('Error: Failed to get ID token');
        return null;
      }
      
      // Convert path to lat/lng format for API
      final pathForApi = path.map((point) => {
        'lat': point['latitude']!,
        'lng': point['longitude']!,
      }).toList();
      
      // Call the territory API with path data directly
      final response = await http.post(
        Uri.parse('$baseUrl/territories/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'path': pathForApi,
          'runId': runId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return data;
        } else {
          print('Territory API error: ${data['error']}');
          return null;
        }
      } else {
        print('Territory API request failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating territory: $e');
      return null;
    }
  }

  /// Fetches all territories for the current user
  static Future<List<Map<String, dynamic>>?> fetchUserTerritories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('fetchUserTerritories: No user logged in');
        return null;
      }
      
      print('fetchUserTerritories: Fetching for user ${user.uid}');
      
      final token = await user.getIdToken();
      if (token == null) {
        print('fetchUserTerritories: Failed to get token');
        return null;
      }

      final url = '$baseUrl/territories/user/${user.uid}';
      print('fetchUserTerritories: Calling $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('fetchUserTerritories: Status ${response.statusCode}');
      print('fetchUserTerritories: Response ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          final territories = List<Map<String, dynamic>>.from(data['territories']);
          print('fetchUserTerritories: Got ${territories.length} territories');
          return territories;
        }
      }
      print('fetchUserTerritories: Returning null');
      return null;
    } catch (e) {
      print('Error fetching territories: $e');
      return null;
    }
  }
  
  /// Formats area in square meters to a human-readable string
  static String formatArea(double areaM2) {
    if (areaM2 < 10000) {
      return '${areaM2.toStringAsFixed(0)} sq meters';
    } else {
      final areaKm2 = areaM2 / 1000000;
      return '${areaKm2.toStringAsFixed(2)} sq km';
    }
  }

  /// Fetches world territories for a list of users (Turf War view)
  static Future<List<Map<String, dynamic>>?> fetchWorldTerritories(List<String> userIds) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/territories/world/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userIds': userIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return List<Map<String, dynamic>>.from(data['territories']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching world territories: $e');
      return null;
    }
  }
  /// Fetches territories for a specific group of users (Dynamic Context)
  static Future<Map<String, dynamic>?> fetchContextTerritories(List<String> userIds) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/territories/context'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userIds': userIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return {
            'territories': List<Map<String, dynamic>>.from(data['territories']),
            'leaderboard': List<Map<String, dynamic>>.from(data['leaderboard'])
          };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching context territories: $e');
      return null;
    }
  }
}
