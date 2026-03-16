import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  // Google Maps API Key (same as used in AndroidManifest)
  static const String _apiKey = 'AIzaSyBSt7L3j1Gtxi_nNhXz8pTcxCXv6niBieg';
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  // Cache to avoid repeated API calls for same coordinates
  static final Map<String, String> _addressCache = {};

  /// Reverse geocode: Convert latitude/longitude to address
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Check cache first
      final cacheKey = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
      if (_addressCache.containsKey(cacheKey)) {
        return _addressCache[cacheKey];
      }

      // Make API call
      final url = Uri.parse(
        '$_geocodingBaseUrl?latlng=$latitude,$longitude&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Geocoding request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            // Get the first result (most accurate)
            final formattedAddress = results[0]['formatted_address'] as String?;
            
            if (formattedAddress != null) {
              // Cache the result
              _addressCache[cacheKey] = formattedAddress;
              return formattedAddress;
            }
          }
        } else if (data['status'] == 'ZERO_RESULTS') {
          return 'Location not found';
        } else {
          print('Geocoding API error: ${data['status']}');
        }
      } else {
        print('Geocoding API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    
    return null;
  }

  /// Get a short address (street name + area) instead of full address
  static Future<String?> getShortAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final fullAddress = await getAddressFromCoordinates(latitude, longitude);
      if (fullAddress == null) return null;

      // Try to extract a shorter version
      // Format: "Street, Area, City, State, Country"
      final parts = fullAddress.split(',');
      if (parts.length >= 2) {
        // Return "Street, Area" or just "Area" if street is too long
        final street = parts[0].trim();
        final area = parts[1].trim();
        
        if (street.length > 30) {
          return area; // Just return area if street name is too long
        }
        return '$street, $area';
      }
      
      return fullAddress;
    } catch (e) {
      print('Error getting short address: $e');
      return null;
    }
  }

  /// Clear the address cache
  static void clearCache() {
    _addressCache.clear();
  }

  /// Calculate road distance between two coordinates using Google Maps Distance Matrix API
  /// Returns distance in kilometers, or null if API call fails
  static Future<double?> getRoadDistance(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$originLat,$originLng'
        '&destinations=$destLat,$destLng'
        '&units=metric'
        '&key=$_apiKey',
      );

      final response = await http.get(url).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Distance Matrix API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['rows'] != null) {
          final rows = data['rows'] as List;
          if (rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List;
            if (elements.isNotEmpty) {
              final element = elements[0] as Map<String, dynamic>;
              if (element['status'] == 'OK' && element['distance'] != null) {
                // Distance is in meters, convert to kilometers
                final distanceInMeters = element['distance']['value'] as int;
                return distanceInMeters / 1000.0;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Distance Matrix API error: $e');
    }
    
    return null;
  }
}
